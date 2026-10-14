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
                        'viewport_height=1080', 'physics_ticks_per_second=60',
                        'max_fps=60', 'window/stretch/aspect="keep"'):
            self.assertIn(setting, config)
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

if __name__ == '__main__':
    unittest.main()
