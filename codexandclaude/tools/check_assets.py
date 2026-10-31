"""ENV-008: validate asset credits, inbox exclusion and Godot 4 PNG imports.

Read-only; called by G3 and available as a standalone command. This validates
the recorded metadata, not the truth of a provider's licensing claims.
"""
import argparse
from collections import Counter
from datetime import date
from pathlib import Path, PurePosixPath
import re
import subprocess
import unicodedata

ROOT = Path(__file__).resolve().parents[2]
COLUMNS = ('文件', '来源', '授权', '作者 / 署名', '日期', '改动', '备注')
EMPTY = {'', '-', '—', '无', 'n/a', '待补', '待定'}


def present(value):
    return value.strip().casefold() not in EMPTY


def normalized(value):
    return unicodedata.normalize('NFKC', value).casefold()


def license_errors(license_name, attribution):
    value = normalized(license_name).strip()
    # These patterns only improve diagnostics. Acceptance below always matches
    # the complete normalized field, including every non-ASCII character.
    if (re.search(r'(?<![a-z])(nc|nd)(?![a-z])', value)
            or re.search(r'(?<![a-z])(?:non[ _-]?commercial|no[ _-]?(?:derivatives|derivs))(?![a-z])', value)
            or re.search(r'^cc[ _-]?by[ _-]?(?:nc|nd)(?:[ _-]|[0-9]|$)', value)
            or any(word in value for word in ('禁止商用', '非商业', '禁止改编', '禁止演绎'))):
        return ['禁止 NC/ND 授权']
    allowed = value in ('cc0', 'ofl-1.1', '免版税可商用', 'ai 生成', '自制')
    by = re.fullmatch(r'cc[ _-]?by[ _-]?[0-9](?:\.[0-9])?', value) is not None
    if not allowed and not by:
        return [f'未知或不允许的授权：{license_name}；须使用白名单格式，CC-BY 须写版本号（如 CC-BY-4.0），说明写备注列']
    if by and not present(attribution):
        return ['CC-BY 缺少作者 / 署名']
    return []


def is_asset(path):
    name = path.name.casefold()
    return not (path.suffix.casefold() in ('.import', '.uid', '.md', '.gd', '.tscn', '.tres', '.gdshader', '.gdshaderinc')
                or name in ('.gitkeep', 'ofl.txt')
                or (path.suffix.casefold() in ('', '.txt') and name.startswith(('readme', 'license', 'licence'))))


def read_rows(path):
    text = path.read_text(encoding='utf-8-sig')
    section = re.search(r'^## 登记表\s*\n(.*?)(?=^## |\Z)', text, re.M | re.S)
    if not section:
        raise ValueError('game/assets/CREDITS.md: 缺少“登记表”节')
    rows = []
    for line in section[1].splitlines():
        if not line.strip().startswith('|'):
            continue
        cells = [cell.strip().replace(r'\|', '|') for cell in re.split(r'(?<!\\)\|', line.strip())[1:-1]]
        if all(re.fullmatch(r':?-+:?', cell) for cell in cells):
            continue
        rows.append(cells)
    if not rows or tuple(rows.pop(0)) != COLUMNS:
        raise ValueError('game/assets/CREDITS.md: 登记表列名必须为 ' + ' / '.join(COLUMNS))
    if any(len(row) != len(COLUMNS) for row in rows):
        raise ValueError('game/assets/CREDITS.md: 登记行必须有七列')
    return [dict(zip(COLUMNS, row)) for row in rows]


def settings(text, section):
    """Read scalar settings only; do not try to parse Godot Object expressions."""
    result = {}
    active = False
    for line in text.splitlines():
        line = line.strip()
        if line.startswith('['):
            active = line == '[' + section + ']'
        elif active and '=' in line and not line.startswith((';', '#')):
            key, value = line.split('=', 1)
            result[key.strip()] = value.split(';', 1)[0].strip()
    return result


def validate_assets(root, tracked_paths, inbox_ignored):
    assets = root / 'game/assets'
    errors = []
    rows = read_rows(assets / 'CREDITS.md')
    entries = Counter()
    for row in rows:
        relative = row['文件'].strip('`')
        path = PurePosixPath(relative)
        if (not relative or path.is_absolute() or '..' in path.parts or '\\' in relative
                or ':' in relative or relative != path.as_posix()):
            errors.append(f'{relative}: 文件路径必须为 game/assets 下的规范相对路径')
            continue
        entries[relative] += 1
        target = assets / relative
        if not target.is_file() or not is_asset(target):
            errors.append(f'{relative}: 登记文件不存在或不属于素材登记范围')
        for reason in license_errors(row['授权'], row['作者 / 署名']):
            errors.append(f'{relative}: {reason}')
        if not present(row['来源']):
            errors.append(f'{relative}: 缺少来源')
        try:
            if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', row['日期']):
                raise ValueError('format')
            date.fromisoformat(row['日期'])
        except ValueError:
            errors.append(f'{relative}: 日期必须是有效的 YYYY-MM-DD')
        if not (row['改动'] == '否' or re.fullmatch(r'是[：:]\s*\S.*', row['改动'])):
            errors.append(f'{relative}: 改动须为“否”或“是：说明”')
        if normalized(row['授权']).strip() == 'ai 生成':
            for field in ('工具', '日期', '套餐', '提示词'):
                match = re.search(field + r'[：:]\s*([^；;]+)', row['备注'])
                if not match or not present(match[1]):
                    errors.append(f'{relative}: AI 备注缺少{field}')
                elif field == '日期' and match[1].strip() != row['日期']:
                    errors.append(f'{relative}: AI 备注日期与生成日期不一致')
    for relative, count in entries.items():
        if count != 1:
            errors.append(f'{relative}: 重复登记（{count} 行）')
    for path in sorted(assets.rglob('*')):
        if path.is_file() and is_asset(path) and path.relative_to(assets).as_posix() not in entries:
            errors.append(f'{path.relative_to(assets).as_posix()}: 未登记素材')
    for path in tracked_paths:
        if path == 'assets_src' or path.startswith('assets_src/'):
            errors.append(f'{path}: 收件箱文件已被 Git 跟踪')
    if not inbox_ignored:
        errors.append('assets_src/: 收件箱未被 .gitignore 忽略')
    project = settings((root / 'game/project.godot').read_text(encoding='utf-8'), 'rendering')
    # Godot 4 ProjectSettings default is 1 (Linear). Filtering is a CanvasItem /
    # project property, not a per-image import parameter as it was in Godot 3.
    if project.get('textures/canvas_textures/default_texture_filter', '1') != '1':
        errors.append('game/project.godot: 2D 默认过滤必须为线性（1）')
    for directory in ('characters', 'environments'):
        for path in sorted((assets / directory).rglob('*')):
            if not path.is_file() or path.suffix.casefold() != '.png':
                continue
            imported = Path(str(path) + '.import')
            label = path.relative_to(root).as_posix()
            if not imported.is_file():
                errors.append(f'{label}: 缺少 .import（先用 Godot 导入并提交设置）')
                continue
            text = imported.read_text(encoding='utf-8-sig')
            if settings(text, 'params').get('mipmaps/generate') != 'false':
                errors.append(f'{label}.import: mipmaps/generate 必须为 false')
            expected = '"res://' + path.relative_to(root / 'game').as_posix() + '"'
            if settings(text, 'deps').get('source_file') != expected:
                errors.append(f'{label}.import: source_file 与素材不符')
    return errors


def check_repository(root):
    tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=root).decode('utf-8').split('\0')
    ignored = subprocess.run(['git', 'check-ignore', '--no-index', '--quiet', 'assets_src/inbox/env008_probe.png'], cwd=root)
    if ignored.returncode not in (0, 1):
        raise RuntimeError('git check-ignore failed')
    return validate_assets(root, tracked, ignored.returncode == 0)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    args = parser.parse_args(argv)
    try:
        errors = check_repository(args.root.resolve())
    except (OSError, ValueError, subprocess.SubprocessError, RuntimeError) as error:
        errors = [str(error)]
    for error in errors:
        print('FAIL: ' + error)
    if not errors:
        print('ASSET_CREDITS checks=registration,licenses,inbox,png_imports failures=0')
    return 1 if errors else 0


if __name__ == '__main__':
    raise SystemExit(main())
