"""Strict Godot validation; import first, then isolated suites in optional parallel workers."""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ERROR_MARKERS = ('SCRIPT ERROR:', 'ERROR:', 'Parse Error', 'ObjectDB instances were leaked')
TESTS = [
    ('platform detours around wide overhangs and real ravine video regression', 'res://tests/test_platform_detour.gd', 'PLATFORM_DETOUR_TESTS checks='),
    ('Boss ordinary monochrome lifecycle and summon separation', 'res://tests/test_boss_ordinary.gd', 'BOSS_ORDINARY_TESTS checks='),
    ('player physics regression', 'res://tests/test_player.gd', 'PLAYER_TESTS checks='),
    ('basic combat regression', 'res://tests/test_combat.gd', 'COMBAT_TESTS checks='),
    ('combat tuning revision', 'res://tests/test_combat_revision.gd', 'COMBAT_REVISION_TESTS checks='),
    ('colorless enemy regression', 'res://tests/test_colorless.gd', 'COLORLESS_TESTS checks='),
    ('player life and death regression', 'res://tests/test_player_life.gd', 'PLAYER_LIFE_TESTS checks='),
    ('enemy melee approach regression', 'res://tests/test_enemy_melee_approach.gd', 'ENEMY_MELEE_TESTS checks='),
    ('possibility dodge and healing regression', 'res://tests/test_possibility.gd', 'POSSIBILITY_TESTS checks='),
    ('attack jumping and airborne dodge regression', 'res://tests/test_air_actions.gd', 'AIR_ACTION_TESTS checks='),
    ('versioned slot persistence regression', 'res://tests/test_slot_store.gd', 'SLOT_STORE_TESTS checks='),
    ('checkpoint and resume integration', 'res://tests/test_checkpoints.gd', 'CHECKPOINT_TESTS checks='),
    ('starting Room and persistent Nodes', 'res://tests/test_start_room.gd', 'START_ROOM_TESTS checks='),
    ('adjacent Rooms and first encounter', 'res://tests/test_two_rooms.gd', 'TWO_ROOM_TESTS checks='),
    ('vertical tower Room and checkpoint return', 'res://tests/test_tower_room.gd', 'TOWER_ROOM_TESTS checks='),
    ('exploration Room and persistent pearl placeholder', 'res://tests/test_exploration_room.gd', 'EXPLORATION_ROOM_TESTS checks='),
    ('connection Room and permanent mechanism', 'res://tests/test_connection_room.gd', 'CONNECTION_ROOM_TESTS checks='),
    ('overlook Boss battle and permanent victory', 'res://tests/test_overlook_boss.gd', 'OVERLOOK_BOSS_TESTS checks='),
    ('Boss pressure and summoned colorless enemies', 'res://tests/test_boss_pressure.gd', 'BOSS_PRESSURE_TESTS checks='),
    ('golden wheat field dialogue and rescue departure', 'res://tests/test_field_room.gd', 'FIELD_ROOM_TESTS checks='),
    ('town rescue and first permanent growth', 'res://tests/test_town_rescue.gd', 'TOWN_RESCUE_TESTS checks='),
    ('ravine checkpoint and persistent second-day event', 'res://tests/test_ravine_day.gd', 'RAVINE_DAY_TESTS checks='),
    ('ravine survivor rescue and deferred growth', 'res://tests/test_ravine_rescue.gd', 'RAVINE_RESCUE_TESTS checks='),
    ('ravine depth clear rescue and pearl persistence', 'res://tests/test_ravine_depth.gd', 'RAVINE_DEPTH_TESTS checks='),
    ('deserter camp exploration and persistent pearl', 'res://tests/test_camp_room.gd', 'CAMP_ROOM_TESTS checks='),
    ('deserter camp waves and formal checkpoint', 'res://tests/test_camp_waves.gd', 'CAMP_WAVES_TESTS checks='),
    ('parasite Boss lifesteal reflection and third-day victory', 'res://tests/test_parasite_boss.gd', 'PARASITE_BOSS_TESTS checks='),
    ('parasite flying support and resource rewards', 'res://tests/test_parasite_support.gd', 'PARASITE_SUPPORT_TESTS checks='),
    ('reverse-time battlefield outskirts and optional spike branch', 'res://tests/test_outskirts.gd', 'OUTSKIRTS_TESTS checks='),
    ('trench traversal checkpoint and pearl persistence', 'res://tests/test_trench.gd', 'TRENCH_TESTS checks='),
    ('monochrome enemy movement attacks dodge and reflection', 'res://tests/test_monochrome.gd', 'MONOCHROME_TESTS checks='),
    ('monochrome trench integration rewards and persistence', 'res://tests/test_monochrome_room.gd', 'MONOCHROME_ROOM_TESTS checks='),
    ('Tian warrior combos guard counter blink and shared attacks', 'res://tests/test_tian.gd', 'TIAN_TESTS checks='),
    ('Tian first introduction freedom rewards and save retries', 'res://tests/test_tian_room.gd', 'TIAN_ROOM_TESTS checks='),
    ('falling debris collision damage scheduler and rubble attacks', 'res://tests/test_rockfall.gd', 'ROCKFALL_TESTS checks='),
    ('second trench negative-resource route and permanent passage', 'res://tests/test_trench_passage.gd', 'TRENCH_PASSAGE_TESTS checks='),
    ('protected enemy actions and future stagger interrupt hook', 'res://tests/test_enemy_interrupts.gd', 'ENEMY_INTERRUPTS_TESTS checks='),
    ('battlefield allied combat reinforcement and checkpoint reset', 'res://tests/test_battlefield.gd', 'BATTLEFIELD_TESTS checks='),
    ('Ten rescue interception cinematic persistence and cooperation', 'res://tests/test_ten_rescue.gd', 'TEN_RESCUE_TESTS checks='),
    ('real input Ten clear aftermath and distinct reinforcement arrival', 'res://tests/test_ten_clear_presentation.gd', 'TEN_CLEAR_PRESENTATION_TESTS checks='),
    ('Ten aggression mobility physical dash and repeated attacks', 'res://tests/test_ten_mobility.gd', 'TEN_MOBILITY_TESTS checks='),
    ('final clock migration bounds and validation', 'res://tests/test_final_clock.gd', 'FINAL_CLOCK_TESTS checks='),
    ('final waves support permanent victory and ending', 'res://tests/test_final_battle.gd', 'FINAL_BATTLE_TESTS checks='),
    ('final timer death load timeout and explicit retry', 'res://tests/test_final_retry.gd', 'FINAL_RETRY_TESTS checks='),
    ('continuous new-game campaign through all Rooms and ending', 'res://tests/test_campaign.gd', 'CAMPAIGN_TESTS checks='),
    ('enemy multi-platform pursuit overhang wall and cliff safety', 'res://tests/test_platform_pursuit.gd', 'PLATFORM_PURSUIT_TESTS checks='),
    ('permanent dodge growth migration physical movement and slot isolation', 'res://tests/test_dodge_growth.gd', 'DODGE_GROWTH_TESTS checks='),
    ('enemy downward platform pursuit safe ledge descent and replanning', 'res://tests/test_platform_descent.gd', 'PLATFORM_DESCENT_TESTS checks='),
    ('outskirts enhanced dodge spike challenge persistence and retry', 'res://tests/test_outskirts_challenge.gd', 'OUTSKIRTS_CHALLENGE_TESTS checks='),
    ('outskirts optional rescue deferred growth abandonment and slot isolation', 'res://tests/test_outskirts_rescue.gd', 'OUTSKIRTS_RESCUE_TESTS checks='),
    ('permanent combat range growth physical hits reflection migration and slots', 'res://tests/test_combat_growth.gd', 'COMBAT_GROWTH_TESTS checks='),
    ('ravine monochrome composition physical pursuit rewards and reset', 'res://tests/test_ravine_monochrome.gd', 'RAVINE_MONOCHROME_TESTS checks='),
]

def execute(engine, project, name, extra, expected=None):
    try:
        result = subprocess.run([engine, '--headless', '--path', project, *extra],
                                capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=60)
        code, output = result.returncode, result.stdout + result.stderr
    except subprocess.TimeoutExpired as error:
        def decode(value):
            return value.decode('utf-8', errors='replace') if isinstance(value, bytes) else (value or '')
        code = 124
        output = decode(error.stdout) + decode(error.stderr) + '\nERROR: suite exceeded 60 seconds\n'
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
    results = {}
    def record(index, result):
        results[index] = result
        logs = [f'Engine: {version}\nWorkers: {args.jobs}']
        logs += [f'=== {name}: exit {code} ===\n{output}' for _,(name,code,output,_) in sorted(results.items())]
        report.write_text('\n'.join(logs), encoding='utf-8')
        print(('PASS ' if result[3] else 'FAIL ') + result[0], flush=True)
        if not result[3]: print(result[2], flush=True)
    for index,(name,extra) in enumerate([
        ('editor import',['--editor','--import','--quit']),
        ('main scene180 frames',['--quit-after','180']),
    ]):
        result = execute(engine,args.project,name,extra)
        record(index,result)
        if not result[3]: return 1
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = {pool.submit(execute,engine,args.project,name,['--script',path],expected): index+2
                   for index,(name,path,expected) in enumerate(TESTS)}
        for future in as_completed(futures): record(futures[future],future.result())
    if not all(result[3] for result in results.values()):
        print(f'Validation failed; report: {report}')
        return 1
    print(f'All engine checks passed. Report: {report}')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
