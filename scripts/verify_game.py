"""Strict verification: actual Godot import, main scene smoke, and physics tests."""
import argparse
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--godot', required=True, help='Godot 4.7.2 console executable')
parser.add_argument('--project', default=str(ROOT / 'game'))
parser.add_argument('--report', default=str(ROOT / 'outputs' / 'engine_validation.txt'))
args = parser.parse_args()
engine = str(Path(args.godot).resolve())
report = Path(args.report)
report.parent.mkdir(parents=True, exist_ok=True)
logs = []

def run(name, extra):
    result = subprocess.run([engine, '--headless', '--path', args.project, *extra],
                            capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=60)
    output = result.stdout + result.stderr
    logs.append(f'=== {name}: exit {result.returncode} ===\n{output}')
    report.write_text('\n'.join(logs), encoding='utf-8')
    if result.returncode != 0 or any(word in output for word in ('SCRIPT ERROR:', 'ERROR:', 'Parse Error')):
        print(output)
        raise SystemExit(f'{name} failed; see {report}')
    print(f'PASS {name}')
    return output

version = subprocess.run([engine, '--version'], capture_output=True, text=True, check=True).stdout.strip()
if not version.startswith('4.7.2.stable.'):
    sys.exit(f'Expected 4.7.2 stable, got {version}')
logs.append('Engine: ' + version)
run('editor import', ['--editor', '--import', '--quit'])
run('main scene 180 frames', ['--quit-after', '180'])
output = run('player physics regression', ['--script', 'res://tests/test_player.gd'])
if 'PLAYER_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful physics test summary')
output = run('basic combat regression', ['--script', 'res://tests/test_combat.gd'])
if 'COMBAT_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful combat test summary')
output = run('combat tuning revision', ['--script', 'res://tests/test_combat_revision.gd'])
if 'COMBAT_REVISION_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful combat revision test summary')
output = run('colorless enemy regression', ['--script', 'res://tests/test_colorless.gd'])
if 'COLORLESS_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful colorless test summary')
output = run('player life and death regression', ['--script', 'res://tests/test_player_life.gd'])
if 'PLAYER_LIFE_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful player life test summary')
print(f'All engine checks passed. Report: {report}')
