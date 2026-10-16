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
    if result.returncode != 0 or any(word in output for word in ('SCRIPT ERROR:', 'ERROR:', 'Parse Error', 'ObjectDB instances were leaked')):
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
output = run('enemy melee approach regression', ['--script', 'res://tests/test_enemy_melee_approach.gd'])
if 'ENEMY_MELEE_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful enemy melee approach test summary')
output = run('possibility dodge and healing regression', ['--script', 'res://tests/test_possibility.gd'])
if 'POSSIBILITY_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful possibility test summary')
output = run('attack jumping and airborne dodge regression', ['--script', 'res://tests/test_air_actions.gd'])
if 'AIR_ACTION_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful air action test summary')
output = run('versioned slot persistence regression', ['--script', 'res://tests/test_slot_store.gd'])
if 'SLOT_STORE_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful slot persistence test summary')
output = run('checkpoint and resume integration', ['--script', 'res://tests/test_checkpoints.gd'])
if 'CHECKPOINT_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful checkpoint test summary')
output = run('starting Room and persistent Nodes', ['--script', 'res://tests/test_start_room.gd'])
if 'START_ROOM_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful starting Room test summary')
output = run('adjacent Rooms and first encounter', ['--script', 'res://tests/test_two_rooms.gd'])
if 'TWO_ROOM_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful two-Room test summary')
output = run('vertical tower Room and checkpoint return', ['--script', 'res://tests/test_tower_room.gd'])
if 'TOWER_ROOM_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful tower Room test summary')
output = run('exploration Room and persistent pearl placeholder', ['--script', 'res://tests/test_exploration_room.gd'])
if 'EXPLORATION_ROOM_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful exploration Room test summary')
output = run('connection Room and permanent mechanism', ['--script', 'res://tests/test_connection_room.gd'])
if 'CONNECTION_ROOM_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful connection Room test summary')
output = run('overlook Boss battle and permanent victory', ['--script', 'res://tests/test_overlook_boss.gd'])
if 'OVERLOOK_BOSS_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful Boss test summary')
output = run('Boss pressure and summoned colorless enemies', ['--script', 'res://tests/test_boss_pressure.gd'])
if 'BOSS_PRESSURE_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful Boss pressure test summary')
output = run('golden wheat field dialogue and rescue departure', ['--script', 'res://tests/test_field_room.gd'])
if 'FIELD_ROOM_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful field Room test summary')
output = run('town rescue and first permanent growth', ['--script', 'res://tests/test_town_rescue.gd'])
if 'TOWN_RESCUE_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful town rescue test summary')
output = run('ravine checkpoint and persistent second-day event', ['--script', 'res://tests/test_ravine_day.gd'])
if 'RAVINE_DAY_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful ravine date test summary')
output = run('ravine survivor rescue and deferred growth', ['--script', 'res://tests/test_ravine_rescue.gd'])
if 'RAVINE_RESCUE_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful ravine rescue test summary')
output = run('ravine depth clear rescue and pearl persistence', ['--script', 'res://tests/test_ravine_depth.gd'])
if 'RAVINE_DEPTH_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful ravine depth test summary')
output = run('deserter camp exploration and persistent pearl', ['--script', 'res://tests/test_camp_room.gd'])
if 'CAMP_ROOM_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful camp Room test summary')
output = run('deserter camp waves and formal checkpoint', ['--script', 'res://tests/test_camp_waves.gd'])
if 'CAMP_WAVES_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful camp wave test summary')
output = run('parasite Boss lifesteal reflection and third-day victory', ['--script', 'res://tests/test_parasite_boss.gd'])
if 'PARASITE_BOSS_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful parasite Boss test summary')
output = run('parasite flying support and resource rewards', ['--script', 'res://tests/test_parasite_support.gd'])
if 'PARASITE_SUPPORT_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful parasite support test summary')
output = run('reverse-time battlefield outskirts and closed ability gate', ['--script', 'res://tests/test_outskirts.gd'])
if 'OUTSKIRTS_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful outskirts test summary')
output = run('trench traversal checkpoint and pearl persistence', ['--script', 'res://tests/test_trench.gd'])
if 'TRENCH_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful trench test summary')
output = run('monochrome enemy movement attacks dodge and reflection', ['--script', 'res://tests/test_monochrome.gd'])
if 'MONOCHROME_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful monochrome test summary')
output = run('monochrome trench integration rewards and persistence', ['--script', 'res://tests/test_monochrome_room.gd'])
if 'MONOCHROME_ROOM_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful monochrome Room test summary')
output = run('Tian warrior combos guard counter blink and shared attacks', ['--script', 'res://tests/test_tian.gd'])
if 'TIAN_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful Tian test summary')
output = run('Tian first introduction freedom rewards and save retries', ['--script', 'res://tests/test_tian_room.gd'])
if 'TIAN_ROOM_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful Tian Room test summary')
output = run('falling debris collision damage scheduler and rubble attacks', ['--script', 'res://tests/test_rockfall.gd'])
if 'ROCKFALL_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful rockfall test summary')
output = run('second trench negative-resource route and permanent passage', ['--script', 'res://tests/test_trench_passage.gd'])
if 'TRENCH_PASSAGE_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful trench passage test summary')
output = run('protected enemy actions and future stagger interrupt hook', ['--script', 'res://tests/test_enemy_interrupts.gd'])
if 'ENEMY_INTERRUPTS_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful enemy interruption test summary')
output = run('battlefield allied combat reinforcement and checkpoint reset', ['--script', 'res://tests/test_battlefield.gd'])
if 'BATTLEFIELD_TESTS checks=' not in output or 'failures=0' not in output:
    sys.exit('Missing successful battlefield test summary')
print(f'All engine checks passed. Report: {report}')
