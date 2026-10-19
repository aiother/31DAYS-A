"""Manual collaboration checks. Python standard library only; no installs or Git writes."""
import argparse
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
TOOLS = ('godot', 'python', 'git', 'node')


class CheckFailure(RuntimeError):
    pass


class Runner:
    def __init__(self, root, directory, timeout, env):
        self.root, self.directory, self.timeout, self.env = root, directory, timeout, env
        self.commands = []

    def run(self, command, timeout=None, stdout_only=False):
        command = [str(value) for value in command]
        index = len(self.commands) + 1
        entry = {'argv': command, 'cwd': str(self.root), 'timeout_seconds': timeout or self.timeout}
        self.commands.append(entry)
        started = time.monotonic()
        try:
            process = subprocess.Popen(command, cwd=self.root, env=self.env,
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                       text=True, encoding='utf-8', errors='replace')
            try:
                output, errors = process.communicate(timeout=entry['timeout_seconds'])
            except subprocess.TimeoutExpired:
                # Kill the verifier AND its Godot workers, rather than leave background checks.
                if os.name == 'nt':
                    try:
                        subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'],
                                       capture_output=True, check=False, timeout=15)
                    finally:
                        process.kill()
                else:
                    process.kill()
                output, errors = process.communicate(timeout=15)
                entry['timed_out'] = True
            entry['exit_code'] = process.returncode
        except (OSError, subprocess.SubprocessError) as error:
            output = str(error)
            errors = ''
            entry['exit_code'] = -1
        entry['seconds'] = round(time.monotonic() - started, 3)
        log = self.directory / f'{index:03d}.txt'
        combined = (output or '') + (errors or '')
        log.write_text(combined, encoding='utf-8')
        entry['log'] = str(log)
        entry['log_sha256'] = hashlib.sha256(log.read_bytes()).hexdigest()
        if entry.get('timed_out') or entry['exit_code'] != 0:
            raise CheckFailure(f'Command failed (exit={entry["exit_code"]}, timeout={entry.get("timed_out", False)}): {command}; log: {log}')
        return (output or '') if stdout_only else combined


def known_paths(tool):
    home = Path.home()
    runtime = home / '.cache/codex-runtimes/codex-primary-runtime/dependencies'
    if tool == 'python':
        return [sys.executable, shutil.which('python'), runtime / 'python/python.exe']
    if tool == 'node':
        return [shutil.which('node'), runtime / 'node/bin/node.exe']
    if tool == 'git':
        return [shutil.which('git'), Path(os.environ.get('ProgramFiles', 'C:/Program Files')) / 'Git/cmd/git.exe']
    candidates = [shutil.which('godot'), shutil.which('godot4')]
    for base in (home / 'Downloads', Path('D:/DMyself')):
        candidates.extend(sorted(base.glob('Godot*/*_console.exe')))
        candidates.extend(sorted(base.glob('Godot*_console.exe')))
    return candidates


def resolve_tool(tool, args, config, env):
    selected = getattr(args, tool) or config.get(tool) or env.get(f'DAYS31_{tool.upper()}')
    candidates = [selected] if selected else known_paths(tool)
    for candidate in candidates:
        if not candidate:
            continue
        path = Path(candidate).expanduser()
        if not path.is_absolute():
            found = shutil.which(str(path))
            path = Path(found) if found else args.root / path
        if not path.is_file():
            continue
        # Auto-discovery must not pick a system Python lacking the workbook dependency.
        if tool == 'python' and not selected:
            try:
                probe = subprocess.run([str(path), '-c', 'import openpyxl'],
                                       capture_output=True, timeout=15)
                if probe.returncode:
                    continue
            except (OSError, subprocess.SubprocessError):
                continue
        return str(path.resolve())
    raise CheckFailure(f'Missing/unusable {tool}; set --{tool}, env.local.json["{tool}"], or DAYS31_{tool.upper()} (see codexandclaude/env.md)')


def load_verifier(root):
    spec = importlib.util.spec_from_file_location('days31_verifier', root / 'scripts/verify_game.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def python_result(output):
    counts = re.findall(r'^Ran (\d+) tests? in ', output, re.M)
    if len(counts) != 1 or int(counts[0]) == 0 or not re.search(r'^OK\s*$', output, re.M):
        raise CheckFailure('Missing/invalid unittest summary (requires positive test count and OK)')
    if re.search(r'^(?:FAILED|ERROR:|FAIL:)', output, re.M):
        raise CheckFailure('Python failure marker')
    return int(counts[0])


def g2_result(output, verifier):
    # Completeness/accounting only. All engine pass/fail decisions remain in verify_game.py.
    expected = ['editor import', 'main scene180 frames', *[name for name, _, _ in verifier.TESTS]]
    observed = re.findall(r'^PASS (.+)$', output, re.M)
    if sorted(observed) != sorted(expected) or 'All engine checks passed. Report:' not in output:
        raise CheckFailure(f'Incomplete verifier summary: expected {len(expected)} entries, observed {len(observed)}')
    return len(expected)


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument('mode', choices=('env', 'focused', 'full'))
    result.add_argument('--root', type=Path, default=ROOT, help='Repository/worktree root; defaults to this script\'s worktree')
    result.add_argument('--config', type=Path, help='JSON config; default <root>/codexandclaude/env.local.json')
    for tool in TOOLS:
        result.add_argument(f'--{tool}')
    result.add_argument('--python-module', action='append', default=[], help='unittest module, e.g. tests.test_game_project; repeatable')
    result.add_argument('--python-all', action='store_true', help='G3 only: both Python test directories')
    result.add_argument('--godot-script', action='append', default=[], help='Registered res:// test script; repeatable')
    result.add_argument('--jobs', type=int, choices=range(1, 9), default=4)
    result.add_argument('--timeout', type=int, default=3600, help='Outer timeout per validation command, seconds')
    return result


def main(argv=None):
    args = parser().parse_args(argv)
    args.root = args.root.resolve()
    directory = args.root / 'codexandclaude/runs' / datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
    directory.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    runner = Runner(args.root, directory, args.timeout, env)
    summary = {'mode': args.mode, 'root': str(args.root), 'started_utc': datetime.now(timezone.utc).isoformat(),
               'sha': None, 'dirty': None, 'tools': {}, 'checks': [], 'commands': runner.commands,
               'passed': False, 'reason': None}
    try:
        if args.timeout <= 0:
            raise CheckFailure('--timeout must be positive')
        if args.mode == 'focused' and not (args.python_module or args.python_all or args.godot_script):
            raise CheckFailure('focused requires --python-module, --python-all or --godot-script')
        if args.mode != 'focused' and (args.python_module or args.python_all or args.godot_script):
            raise CheckFailure('Focused selectors require focused mode')
        config_path = args.config or args.root / 'codexandclaude/env.local.json'
        config = json.loads(config_path.read_text(encoding='utf-8-sig')) if config_path.exists() else {}
        if args.config and not args.config.exists():
            raise CheckFailure(f'Config does not exist: {args.config}')
        if not isinstance(config, dict) or set(config) - set(TOOLS):
            raise CheckFailure('Config must be an object containing only godot/python/git/node paths')
        for tool in config:
            if not isinstance(config[tool], str) or not config[tool]:
                raise CheckFailure(f'Config {tool} must be a nonempty path string')
        git = resolve_tool('git', args, config, env)
        summary['sha'] = runner.run([git, 'rev-parse', 'HEAD'], 30, stdout_only=True).strip()
        status = runner.run([git, 'status', '--porcelain', '--untracked-files=all'], 30, stdout_only=True)
        summary['dirty'] = bool(status.strip())
        summary['status'] = status.splitlines()
        for tool in TOOLS:
            path = resolve_tool(tool, args, config, env)
            summary['tools'][tool] = {'path': path}
            if tool == 'python':
                version = runner.run([path, '-c', 'import sys,openpyxl; print(sys.version.split()[0]); print("openpyxl="+openpyxl.__version__)'], 30).strip()
                if 'openpyxl=' not in version:
                    raise CheckFailure('Python dependency probe missing openpyxl version')
            else:
                version = runner.run([path, '--version'], 30).strip()
            summary['tools'][tool]['version'] = version
            if tool == 'godot' and not version.startswith('4.7.2.stable.'):
                raise CheckFailure(f'Expected Godot 4.7.2 stable, got {version}')
        env['DAYS31_NODE'] = summary['tools']['node']['path']
        python = summary['tools']['python']['path']
        verifier = load_verifier(args.root) if args.mode != 'env' else None
        if args.mode == 'full':
            report = directory / 'engine.txt'
            output = runner.run([python, args.root / 'scripts/verify_game.py', '--godot', summary['tools']['godot']['path'],
                                 '--project', args.root / 'game', '--report', report, '--jobs', args.jobs])
            count = g2_result(output, verifier)
            summary['checks'].append({'gate': 'G2', 'expected': len(verifier.TESTS) + 2, 'executed': count, 'passed': True,
                                      'report': str(report), 'sha256': hashlib.sha256(report.read_bytes()).hexdigest()})
        if args.mode == 'focused' and args.godot_script:
            # Import first, as in the existing verifier; execute() owns all Godot decisions.
            for script in args.godot_script:
                if script not in {path for _, path, _ in verifier.TESTS}:
                    raise CheckFailure(f'Unregistered Godot script: {script}')
            adapter = ('import importlib.util,sys; '
                       's=importlib.util.spec_from_file_location("v",sys.argv[1]); '
                       'v=importlib.util.module_from_spec(s); s.loader.exec_module(v); '
                       'row=next((r for r in v.TESTS if r[1]==sys.argv[4]),None); '
                       'r=v.execute(sys.argv[2],sys.argv[3],row[0] if row else "editor import",'
                       '["--script",row[1]] if row else ["--editor","--import","--quit"],row[2] if row else None); '
                       'print(r[2]); print("FOCUSED_VERIFIER_PASS" if r[3] else "FOCUSED_VERIFIER_FAIL"); sys.exit(0 if r[3] else 1)')
            for script in ['', *args.godot_script]:
                output = runner.run([python, '-c', adapter, args.root / 'scripts/verify_game.py',
                                     summary['tools']['godot']['path'], args.root / 'game', script])
                if not re.search(r'^FOCUSED_VERIFIER_PASS\s*$', output, re.M):
                    raise CheckFailure('Missing focused Godot summary')
                summary['checks'].append({'gate': 'G1 Godot', 'script': script or 'editor import', 'passed': True})
        if args.mode == 'full' or args.python_all:
            for folder in ('tests', 'codexandclaude/tests'):
                output = runner.run([python, '-m', 'unittest', 'discover', '-s', folder, '-v'])
                count = python_result(output)
                summary['checks'].append({'gate': 'G3', 'directory': folder, 'executed': count, 'complete': True, 'passed': True})
        if args.mode == 'focused':
            for module in args.python_module:
                output = runner.run([python, '-m', 'unittest', '-v', module])
                count = python_result(output)
                summary['checks'].append({'gate': 'G1 Python', 'module': module, 'executed': count, 'passed': True})
        summary['passed'] = True
    except (CheckFailure, OSError, ValueError, ImportError) as error:
        summary['reason'] = str(error)
    summary['finished_utc'] = datetime.now(timezone.utc).isoformat()
    summary_path = directory / 'summary.json'
    summary_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    print(f'Summary: {summary_path}')
    return 0 if summary['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
