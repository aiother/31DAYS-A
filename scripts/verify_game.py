"""Strict Godot validation; import first, then isolated suites in optional parallel workers."""
import argparse
from collections import Counter
import json
from typing import NamedTuple
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ERROR_MARKERS = ('SCRIPT ERROR:', 'ERROR:', 'Parse Error', 'ObjectDB instances were leaked')
# Each runnable test owns its registration. Exclusions are only for non-runnable
# test_*.gd helpers and must state why they are excluded; currently there are none.
EXCLUDED_TESTS = {}
HEADER = '# verify-suite: '


class Suite(NamedTuple):
    name: str
    path: str
    marker: str
    fixed_fps: int | None
    timeout: int


def discover_suites(project, excluded=None):
    project = Path(project)
    excluded = EXCLUDED_TESTS if excluded is None else excluded
    files = {'res://' + file.relative_to(project).as_posix(): file
             for file in sorted((project / 'tests').rglob('test_*.gd'))}
    if not files:
        raise ValueError('No test_*.gd files found in ' + str(project / 'tests'))
    for uri, reason in excluded.items():
        if uri not in files or not isinstance(reason, str) or not reason.strip():
            raise ValueError('Exclusion requires an existing test file and a reason: ' + uri)
    suites = []
    seen = {field: set() for field in ('path', 'name', 'marker')}
    for owner, file in files.items():
        first = file.read_text(encoding='utf-8-sig').splitlines()[0:1]
        registered = bool(first and first[0].startswith(HEADER))
        if owner in excluded:
            if registered:
                raise ValueError('Excluded test is also registered: ' + owner)
            continue
        if not registered:
            raise ValueError('Missing suite metadata: ' + owner)
        try:
            data = json.loads(first[0][len(HEADER):])
        except ValueError as error:
            raise ValueError('Invalid suite JSON: ' + owner) from error
        if not isinstance(data, dict) or set(data) != set(Suite._fields):
            raise ValueError('Suite must declare exactly ' + ', '.join(Suite._fields) + ': ' + owner)
        for field in ('path', 'name', 'marker'):
            value = data[field]
            if not isinstance(value, str) or not value.strip():
                raise ValueError('Invalid ' + field + ': ' + owner)
            if value in seen[field]:
                raise ValueError('Duplicate suite ' + field + ': ' + value)
            seen[field].add(value)
        uri = data['path']
        if not re.fullmatch(r'res://tests/(?:[A-Za-z0-9_-]+/)*test_[A-Za-z0-9_-]+\.gd', uri):
            raise ValueError('Invalid suite resource path: ' + uri)
        if not (project / uri.removeprefix('res://')).is_file():
            raise ValueError('Registered file does not exist: ' + uri)
        if uri != owner:
            raise ValueError('Suite path must point to its own file: ' + owner)
        if data['name'] in ('editor import', 'main scene180 frames'):
            raise ValueError('Suite name is reserved: ' + data['name'])
        if not re.fullmatch(r'[A-Z][A-Z0-9_]* checks=', data['marker']):
            raise ValueError('Invalid result marker: ' + owner)
        if type(data['timeout']) is not int or data['timeout'] <= 0:
            raise ValueError('timeout must be a positive integer: ' + owner)
        if data['fixed_fps'] is not None and (type(data['fixed_fps']) is not int or data['fixed_fps'] <= 0):
            raise ValueError('fixed_fps must be null or a positive integer: ' + owner)
        suites.append(Suite(**data))
    return suites


def validate_executed(suites, executed):
    expected = Counter(suite.path for suite in suites)
    actual = Counter(executed)
    if actual != expected:
        raise ValueError(f'Incorrect execution set: missing={list((expected-actual).elements())}, extra={list((actual-expected).elements())}')


SUITES = discover_suites(ROOT / 'game')
# Compatibility for report accounting and existing consumers; never a second list.
TESTS = [(suite.name, suite.path, suite.marker) for suite in SUITES]


def execute_suite(engine, project, suite):
    return execute(engine, project, suite.name, ['--script', suite.path], suite.marker,
                   fixed_fps=suite.fixed_fps, timeout=suite.timeout)

def execute(engine, project, name, extra, expected=None, *, fixed_fps=None, timeout=60):
    if fixed_fps is not None:
        extra = ['--fixed-fps', str(fixed_fps), *extra]
    try:
        result = subprocess.run([engine, '--headless', '--path', project, *extra],
                                capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=timeout)
        code, output = result.returncode, result.stdout + result.stderr
    except subprocess.TimeoutExpired as error:
        def decode(value):
            return value.decode('utf-8', errors='replace') if isinstance(value, bytes) else (value or '')
        code = 124
        output = decode(error.stdout) + decode(error.stderr) + f'\nERROR: suite exceeded {timeout} seconds\n'
    passed = code == 0 and not any(marker in output for marker in ERROR_MARKERS)
    if expected:
        passed = passed and re.search(re.escape(expected) + r'\d+ failures=0(?:\r?\n|$)', output) is not None
    return name, code, output, passed

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', required=True, help='Godot 4.7.2 console executable')
    parser.add_argument('--project', default=str(ROOT / 'game'))
    parser.add_argument('--report', default=str(ROOT / 'outputs' / 'engine_validation.txt'))
    parser.add_argument('--jobs', type=int, choices=range(1,9), default=1, help='Isolated test processes; default serial, recommended4 for faster validation')
    args = parser.parse_args()
    engine = str(Path(args.godot).resolve())
    report = Path(args.report)
    report.parent.mkdir(parents=True, exist_ok=True)
    version = subprocess.run([engine, '--version'], capture_output=True, text=True, check=True).stdout.strip()
    if not version.startswith('4.7.2.stable.'):
        sys.exit(f'Expected4.7.2 stable, got {version}')
    try:
        suites = discover_suites(args.project)
    except ValueError as error:
        print('Invalid suite registry: ' + str(error), file=sys.stderr)
        return 1
    results = {}
    executed = []
    def record(index, result):
        results[index] = result
        logs = [f'Engine: {version}\nWorkers: {args.jobs}']
        logs += [f'=== {name}: exit {code} ===\n{output}' for _,(name,code,output,_) in sorted(results.items())]
        report.write_text('\n'.join(logs), encoding='utf-8')
        print(('PASS ' if result[3] else 'FAIL ') + result[0], flush=True)
        if not result[3]:
            output = result[2]
            if len(output)>12000:
                lines=output.splitlines()
                diagnostics=[line for line in lines if any(marker in line for marker in ERROR_MARKERS) or re.search(r'failures=[1-9]',line)]
                output='\n'.join(diagnostics+lines[-20:])
            print(output, flush=True)
    for index,(name,extra) in enumerate([
        ('editor import',['--editor','--import','--quit']),
        ('main scene180 frames',['--quit-after','180']),
    ]):
        result = execute(engine,args.project,name,extra)
        record(index,result)
        if not result[3]: return 1
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = {pool.submit(execute_suite, engine, args.project, suite): (index+2, suite.path)
                   for index, suite in enumerate(suites)}
        for future in as_completed(futures):
            index, uri = futures[future]
            result = future.result()
            executed.append(uri)
            record(index, result)
    try:
        validate_executed(suites, executed)
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return 1
    if not all(result[3] for result in results.values()):
        print(f'Validation failed; report: {report}')
        return 1
    print(f'All engine checks passed. Report: {report}')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
