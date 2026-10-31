"""ENV-008: exercise rejection cases and run the actual registry check in G3."""
from pathlib import Path
import tempfile
import unittest

from codexandclaude.tools import check_assets as checker


class AssetRegistryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.assets = self.root / 'game/assets'
        self.assets.mkdir(parents=True)
        (self.root / 'game/project.godot').write_text('[rendering]\n', encoding='utf-8')
        self.row = ['`characters/test.svg`', '自制', '自制', '—', '2026-10-30', '否', '—']
        self.asset('characters/test.svg')
        self.credits([self.row])

    def asset(self, name):
        path = self.assets / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b'fixture')
        return path

    def credits(self, rows):
        text = '## 登记表\n\n| ' + ' | '.join(checker.COLUMNS) + ' |\n| ' + ' | '.join(['---'] * 7) + ' |\n'
        text += ''.join('| ' + ' | '.join(row) + ' |\n' for row in rows)
        (self.assets / 'CREDITS.md').write_text(text, encoding='utf-8')

    def errors(self, tracked=(), ignored=True):
        return '\n'.join(checker.validate_assets(self.root, tracked, ignored))

    def test_current_repository_passes_all_checks(self):
        self.assertEqual([], checker.check_repository(checker.ROOT))

    def test_valid_registry_excludes_generated_resources_and_documentation(self):
        for name in ('fonts/OFL.txt', 'fonts/README.md', 'fonts/LICENSE.txt', 'characters/rig.tscn', 'characters/idle.tres', 'characters/rig.gd', 'characters/rig.gd.uid', 'test.svg.import', '.gitkeep'):
            self.asset(name)
        self.assertEqual('', self.errors())

    def test_unregistered_and_unknown_extension_assets_fail_with_path(self):
        for name in ('audio/sound.wav', 'characters/source.psd', 'characters/README.png', 'characters/LICENSE.svg'):
            self.asset(name)
            self.assertIn(name + ': 未登记素材', self.errors())

    def test_missing_file_and_duplicate_row_fail(self):
        self.credits([self.row, self.row])
        self.assertIn('characters/test.svg: 重复登记', self.errors())
        (self.assets / 'characters/test.svg').unlink()
        self.assertIn('characters/test.svg: 登记文件不存在', self.errors())

    def test_restrictive_license_variations_fail(self):
        for value in ('NC', 'nd', 'CC-BY-NC-4.0', 'cc by nd 4.0', 'CC_BY_NC_SA_4.0', 'CCBYNC4.0', 'NonCommercial', 'Non-Commercial', 'NoDerivatives', 'No Derivatives', 'NoDerivs', '非商业', '禁止改编', 'ＣＣ－ＢＹ－ＮＣ－４.０'):
            with self.subTest(license=value):
                self.row[2] = value
                self.credits([self.row])
                self.assertIn('characters/test.svg: 禁止 NC/ND', self.errors())

    def test_unknown_license_and_missing_attribution_fail(self):
        self.row[2] = 'CC-BY-4.0'
        self.credits([self.row])
        self.assertIn('CC-BY 缺少', self.errors())
        self.row[3] = 'Example Author'
        self.credits([self.row])
        self.assertEqual('', self.errors())
        self.row[2] = 'unknown'
        self.credits([self.row])
        self.assertIn('未知或不允许', self.errors())

    def test_license_suffixes_cannot_be_erased_into_allowed_labels(self):
        self.row[3] = 'Example Author'
        for value in ('CC-BY-4.0（不可商用）', 'CC-BY 4.0 仅限个人学习',
                      'CC-BY 4.0（非商用）', 'CC BY 4.0 不得商用',
                      'CC-BY 4.0 （禁止二次创作）', 'CC-BY-4.0（无额外限制）'):
            with self.subTest(license=value):
                self.row[2] = value
                self.credits([self.row])
                self.assertTrue(checker.license_errors(value, self.row[3]))
                self.assertIn('characters/test.svg:', self.errors())

    def test_unrecognized_words_do_not_report_an_embedded_nd_as_a_license(self):
        for value in ('CC-BY-4.0 (Candy)', 'CC-BY-4.0 Fonds'):
            with self.subTest(license=value):
                errors = '\n'.join(checker.license_errors(value, 'Example Author'))
                self.assertIn('未知或不允许', errors)
                self.assertNotIn('禁止 NC/ND', errors)

    def test_normalized_license_whitelist_and_version_formats(self):
        for value in ('CC0', 'cc0', 'ＣＣ０', 'OFL-1.1', 'ofl-1.1', '免版税可商用',
                      'AI 生成', 'ai 生成', '自制', 'CC-BY-4.0', 'CC BY 3',
                      'cc_by_4.0', 'ccby4.0', 'ＣＣ－ＢＹ－４．０'):
            with self.subTest(allowed=value):
                self.assertEqual([], checker.license_errors(value, 'Example Author'))
        for value in ('CC-BY', 'CC0-1.0', 'CCBY40', 'CC-BY-4..0', 'CC-BY-4.0.1',
                      'CC-BY-SA-4.0', 'MIT', 'Apache-2.0', 'CC  BY 4.0'):
            with self.subTest(rejected=value):
                errors = '\n'.join(checker.license_errors(value, 'Example Author'))
                self.assertIn('未知或不允许', errors)
                self.assertIn('版本号', errors)
        self.assertIn('CC-BY 缺少', '\n'.join(checker.license_errors('ＣＣ－ＢＹ－４．０', '—')))

    def test_normalized_ai_labels_still_require_generation_metadata(self):
        for value in ('AI 生成', 'ai 生成', 'ＡＩ 生成'):
            with self.subTest(license=value):
                self.row[2] = value
                self.credits([self.row])
                self.assertIn('AI 备注缺少工具', self.errors())

    def test_ai_metadata_requires_tool_date_plan_and_prompt(self):
        self.row[2] = 'AI 生成'
        valid = ['工具：GPT Image 2', '日期：2026-10-30', '套餐：付费', '提示词：tasks/prompt.md']
        self.row[6] = '；'.join(valid)
        self.credits([self.row])
        self.assertEqual('', self.errors())
        for i, field in enumerate(('工具', '日期', '套餐', '提示词')):
            with self.subTest(field=field):
                self.row[6] = '；'.join(valid[:i] + valid[i + 1:])
                self.credits([self.row])
                self.assertIn('AI 备注缺少' + field, self.errors())
        self.row[6] = '；'.join(valid).replace('2026-10-30', '2026-10-29')
        self.credits([self.row])
        self.assertIn('日期不一致', self.errors())

    def test_tracked_and_unignored_inbox_fail(self):
        self.assertIn('assets_src/inbox/raw.png: 收件箱文件已被 Git 跟踪', self.errors(['assets_src/inbox/raw.png']))
        self.assertIn('收件箱未被 .gitignore 忽略', self.errors(ignored=False))
        self.assertEqual('', self.errors(['game/assets/characters/test.svg']))

    def test_bad_paths_dates_sources_and_modification_metadata_fail(self):
        for column, value, reason in ((0, '`../escape.svg`', '规范相对路径'), (0, '`/tmp/escape.svg`', '规范相对路径'), (0, '`a\\b.svg`', '规范相对路径'), (0, '`characters//test.svg`', '规范相对路径'), (1, '—', '缺少来源'), (4, '2026-02-30', '日期必须'), (5, '是', '改动须')):
            with self.subTest(column=column, value=value):
                row = self.row.copy()
                row[column] = value
                self.credits([row])
                self.assertIn(reason, self.errors())

    def test_import_must_exist_match_source_and_disable_mipmaps(self):
        path = self.asset('environments/test.png')
        row = self.row.copy()
        row[0] = '`environments/test.png`'
        self.credits([self.row, row])
        self.assertIn('environments/test.png: 缺少 .import', self.errors())
        imported = Path(str(path) + '.import')
        valid = '[deps]\nsource_file="res://assets/environments/test.png"\n[params]\nmipmaps/generate=false\n'
        imported.write_text(valid)
        self.assertEqual('', self.errors())
        imported.write_text(valid.replace('false', 'true'))
        self.assertIn('mipmaps/generate 必须为 false', self.errors())
        imported.write_text(valid.replace('test.png', 'wrong.png'))
        self.assertIn('source_file 与素材不符', self.errors())
        (self.root / 'game/project.godot').write_text('[rendering]\ntextures/canvas_textures/default_texture_filter=0\n')
        self.assertIn('默认过滤必须为线性', self.errors())

    def test_malformed_table_fails_closed(self):
        for text in ('## Wrong\n', '## 登记表\n| 文件 | 来源 |\n', '## 登记表\n| ' + ' | '.join(checker.COLUMNS) + ' |\n| incomplete |\n'):
            (self.assets / 'CREDITS.md').write_text(text, encoding='utf-8')
            with self.assertRaises(ValueError):
                self.errors()


if __name__ == '__main__':
    unittest.main()
