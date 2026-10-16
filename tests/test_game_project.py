"""Offline structural guards; physics behavior is verified by game/tests/test_player.gd."""
from pathlib import Path
import re
import unittest

GAME = Path(__file__).resolve().parents[1] / 'game'

class GameProjectTests(unittest.TestCase):
    def test_all_resource_references_resolve(self):
        for file in GAME.rglob('*'):
            if '.godot' in file.parts or file.suffix not in ('.godot', '.gd', '.tres', '.tscn'):
                continue
            for relative in re.findall(r'res://([^"\s]+)', file.read_text(encoding='utf-8')):
                self.assertTrue((GAME / relative).is_file(), (file, relative))

    def test_engine_and_screen_baseline(self):
        config = (GAME / 'project.godot').read_text(encoding='utf-8')
        for setting in ('"4.7"', '"gl_compatibility"', 'viewport_width=1920',
                        'viewport_height=1080', 'max_fps=60'):
            self.assertIn(setting, config)
        # Godot removes explicit default values when saving project settings.
        for key, default in [('common/physics_ticks_per_second', '60'),
                             ('window/stretch/aspect', '"keep"')]:
            value = re.search(r'^' + re.escape(key) + r'=(.*)$', config, re.M)
            self.assertEqual(value.group(1) if value else default, default)
        export = (GAME / 'export_presets.cfg').read_text(encoding='utf-8')
        self.assertIn('binary_format/architecture="x86_64"', export)

    def test_keyboard_controller_and_future_actions(self):
        config = (GAME / 'project.godot').read_text(encoding='utf-8')
        for action in ('move_left', 'move_right', 'aim_up', 'aim_down', 'run',
                       'jump', 'attack', 'dodge', 'recover', 'interact', 'use_item', 'pause'):
            body = re.search(r'^' + action + r'=\{(.*?)\n\}', config, re.M | re.S).group(1)
            self.assertIn('InputEventKey', body)
            self.assertRegex(body, 'InputEventJoypad(Button|Motion)')
        self.assertIn('InputEventMouseButton', config)
        lab = (GAME / 'debug/movement_lab.tscn').read_text(encoding='utf-8')
        self.assertIn('LB 跑步', lab)
        run = re.search(r'^run=\{(.*?)\n\}', config, re.M | re.S).group(1)
        self.assertIn('"button_index":9', run)

    def test_visual_physics_separation_and_inactive_combat(self):
        player = (GAME / 'player/player.tscn').read_text(encoding='utf-8')
        self.assertIn('type="CharacterBody2D"', player)
        self.assertIn('name="BodyCollision"', player)
        for name in ('GameplayRoot', 'VisualRoot', 'Hitbox', 'Hurtbox', 'InteractionArea'):
            self.assertIn(f'name="{name}"', player)
        self.assertEqual(player.count('disabled = true'), 3)
        visual = (GAME / 'player/placeholder_visual.gd').read_text(encoding='utf-8')
        self.assertNotIn('move_and_slide', visual)
        self.assertNotIn('player.velocity =', visual)
        lab = (GAME / 'debug/movement_lab.tscn').read_text(encoding='utf-8')
        self.assertIn('type="TileMapLayer"', lab)
        self.assertNotIn('colorless_entity', lab)
        self.assertFalse(list(GAME.rglob('*.gdextension')))

    def test_parameters_remain_data_driven_and_lfs_configured(self):
        self.assertIn('extends Resource', (GAME / 'player/movement_config.gd').read_text(encoding='utf-8'))
        controller = (GAME / 'player/player_controller.gd').read_text(encoding='utf-8')
        self.assertIn('@export var movement: MovementConfig', controller)
        self.assertIn('movement.edge_grace_distance', controller)
        attrs = (GAME.parent / '.gitattributes').read_text(encoding='utf-8')
        for extension in ('png', 'wav', 'spine', 'skel', 'psd'):
            self.assertIn(f'*.{extension} filter=lfs', attrs)

    def test_basic_combat_uses_frozen_damage_and_debug_targets(self):
        config = (GAME / 'data/combat/graybox_attack.tres').read_text(encoding='utf-8')
        self.assertIn('damage = 5', config)
        lab = (GAME / 'debug/combat_lab.tscn').read_text(encoding='utf-8')
        self.assertIn('res://debug/combat_target.tscn', lab)
        self.assertNotIn('colorless_entity', lab)
        project = (GAME / 'project.godot').read_text(encoding='utf-8')
        self.assertIn('run/main_scene="res://world/outskirts_session.tscn"', project)
        receiver = (GAME / 'systems/combat/combat_hurtbox.gd').read_text(encoding='utf-8')
        self.assertIn('signal hit_received', receiver)
        self.assertNotIn('current_health', receiver)

    def test_colorless_baseline_and_live_player_damage(self):
        config = (GAME / 'data/enemies/colorless_entity.tres').read_text(encoding='utf-8')
        for setting in ('max_health = 13', 'damage = 1', 'reward = 2'):
            self.assertIn(setting, config)
        lab = (GAME / 'debug/enemy_lab.tscn').read_text(encoding='utf-8')
        self.assertIn('res://enemies/colorless_entity.tscn', lab)
        self.assertIn('玩家开场生命3/5', lab)
        self.assertNotIn('单色实体', lab)
        self.assertNotIn('天人战士', lab)

    def test_life_defaults_and_checkpoint_restart_are_explicit(self):
        config = (GAME / 'data/player/graybox_life.tres').read_text(encoding='utf-8')
        for setting in ('max_health = 5', 'initial_health = 3', 'downed_duration = 1.0', 'respawn_protection = 3.0'):
            self.assertIn(setting, config)
        ui = (GAME / 'ui/menus/life_ui.gd').read_text(encoding='utf-8')
        self.assertIn('从检查点继续', ui)
        self.assertIn('重新挑战（灰盒出生点）', ui)
        self.assertIn('Node.PROCESS_MODE_ALWAYS', ui)

    def test_enemy_melee_approach_regression_is_in_verification(self):
        verifier = (GAME.parent / 'scripts/verify_game.py').read_text(encoding='utf-8')
        self.assertIn('res://tests/test_enemy_melee_approach.gd', verifier)
        doc = (GAME / 'docs/colorless_implementation.md').read_text(encoding='utf-8')
        self.assertIn('400px', doc)
        self.assertIn('AI修复', doc)

    def test_oct15_revision_marked_in_related_documents(self):
        for name in ['T1_核心玩法与玩家操作.md', 'T2_战斗系统.md', 'T3_可能性_基础属性_成长_死亡.md']:
            document = (GAME.parent / 'Words' / name).read_text(encoding='utf-8')
            self.assertIn('2026-10-15', document)
            self.assertIn('2倍', document)
            self.assertIn('长按跳跃最大高度的50%', document)
        for name in ['T1_核心玩法与玩家操作.md', 'T2_战斗系统.md']:
            document = (GAME.parent / 'Words' / name).read_text(encoding='utf-8')
            self.assertIn('0.5秒', document)
            self.assertNotIn('攻击时可低速移动', document)
            self.assertNotIn('移动速度大幅降低', document)

if __name__ == '__main__':
    unittest.main()
