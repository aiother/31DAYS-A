"""Evidence rendering and read-only Git content comparison (standard library only)."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

# Deliberately not all tasks/: task requirements and executable helpers remain in scope.
SCOPE = ['exclude codexandclaude/runs/**',
         'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']
RECORD = re.compile(r'codexandclaude/tasks/[A-Z]+-\d+/(delivery|review|integration|acceptance)\.md\Z')


def record_path(path):
    return path.startswith('codexandclaude/runs/') or bool(RECORD.fullmatch(path))


def digest(data):
    return hashlib.sha256(data).hexdigest()


def manifest_digest(rows, scoped=False):
    rows = [row for row in rows if not scoped or not record_path(row['path'])]
    return digest(json.dumps(sorted(rows, key=lambda r: r['path']), ensure_ascii=True,
                             sort_keys=True, separators=(',', ':')).encode('utf-8'))


def git_bytes(root, git, *args):
    result = subprocess.run([str(git), *map(str, args)], cwd=root, capture_output=True, timeout=60)
    if result.returncode:
        raise ValueError(f'Git evidence command failed: {args}: {result.stderr.decode("utf-8", "replace")}')
    return result.stdout


def commit_manifest(root, git, ref):
    # Resolve before using ref in option-bearing commands; paths with leading '-' cannot be options.
    sha = git_bytes(root, git, 'rev-parse', '--verify', '--end-of-options', f'{ref}^{{commit}}').decode().strip()
    tree = git_bytes(root, git, 'rev-parse', f'{sha}^{{tree}}').decode().strip()
    rows = []
    for entry in git_bytes(root, git, 'ls-tree', '-rz', '--full-tree', sha).split(b'\0'):
        if not entry:
            continue
        meta, path = entry.split(b'\t', 1)
        mode, kind, oid = meta.decode('ascii').split()
        if kind != 'blob':
            raise ValueError('Submodules are not supported as reusable evidence content')
        rows.append({'path': path.decode('utf-8'), 'mode': mode, 'oid': oid})
    return sha, tree, rows


def snapshot(root, git):
    """Raw file SHA256 binds dirty bytes; Git tree fingerprints bind committed content.

    They are separate because CRLF checkout and LFS smudge need not equal stored blob bytes.
    No Git index/write commands or clean filters are invoked here.
    """
    root = Path(root)
    sha, tree, committed = commit_manifest(root, git, 'HEAD')
    status = git_bytes(root, git, 'status', '--porcelain=v1', '-z', '--untracked-files=all')
    rows, untracked = [], []
    tracked = {}
    for entry in git_bytes(root, git, 'ls-files', '--stage', '-z').split(b'\0'):
        if not entry:
            continue
        meta, path = entry.split(b'\t', 1)
        mode, _, stage = meta.decode('ascii').split()
        if stage != '0' or mode == '160000':
            raise ValueError('Unmerged entries/submodules cannot provide a content snapshot')
        tracked[path.decode('utf-8')] = mode
    others = [p.decode('utf-8') for p in git_bytes(root, git, 'ls-files', '--others', '--exclude-standard', '-z').split(b'\0') if p]
    for path in sorted(set(tracked) | set(others)):
        relative = Path(path)
        if relative.is_absolute() or '..' in relative.parts:
            raise ValueError(f'Unsafe repository path: {path}')
        file = root / relative
        if file.is_symlink():
            data, mode = os.readlink(file).encode('utf-8'), '120000'
        elif file.is_file():
            data = file.read_bytes()
            mode = tracked.get(path, '100644')
            if os.name != 'nt' and mode != '120000':
                mode = '100755' if file.stat().st_mode & 0o111 else '100644'
        elif path in tracked and not file.exists():
            continue  # A deletion is represented by absence from the manifest.
        else:
            raise ValueError(f'Cannot fingerprint non-file: {path}')
        row = {'path': path, 'mode': mode, 'sha256': digest(data)}
        rows.append(row)
        if path in others:
            untracked.append(row)
    hashes = {}
    for name, options in (('tracked_diff_sha256', ['HEAD']),
                          ('staged_diff_sha256', ['--cached', 'HEAD']),
                          ('unstaged_diff_sha256', [])):
        hashes[name] = digest(git_bytes(root, git, 'diff', '--binary', '--no-ext-diff', '--no-textconv', *options, '--'))
    return {'schema': 1, 'scope': list(SCOPE), 'sha': sha, 'head_tree': tree,
            'dirty': bool(status), 'status_sha256': digest(status),
            'full_sha256': manifest_digest(rows), 'scoped_sha256': manifest_digest(rows, True),
            'commit_scoped_sha256': manifest_digest(committed, True),
            'untracked': untracked, **hashes}


def check_key(check):
    if check.get('gate') == 'G3':
        return 'G3:' + check.get('directory', '')
    if check.get('gate') == 'G1 Python':
        return 'G1 Python:' + check.get('module', '')
    if check.get('gate') == 'G1 Godot':
        return 'G1 Godot:' + check.get('script', '')
    return check.get('gate', '')


def validation_errors(summary):
    errors = []
    if not isinstance(summary, dict):
        return ['摘要必须是JSON对象']
    if summary.get('finalized') is not True or not summary.get('finished_utc'):
        errors.append('缺少最终汇总')
    if summary.get('passed') is not True or summary.get('reason'):
        errors.append(summary.get('reason') or '运行未通过')
    planned = summary.get('planned_checks')
    checks = summary.get('checks', [])
    commands = summary.get('commands', [])
    if not isinstance(checks, list) or not all(isinstance(c, dict) for c in checks):
        return errors + ['检查字段格式无效']
    if not isinstance(commands, list) or not all(isinstance(c, dict) for c in commands):
        return errors + ['命令字段格式无效']
    if not isinstance(planned, list) or [check_key(c) for c in checks] != planned:
        errors.append('关卡未全部完成或执行集合不匹配')
    if summary.get('mode') == 'full' and planned != ['G2', 'G3:tests', 'G3:codexandclaude/tests']:
        errors.append('full缺少规定关卡')
    if summary.get('mode') == 'focused' and not planned:
        errors.append('focused未指定检查')
    for c in checks:
        if c.get('passed') is not True:
            errors.append(f'{check_key(c)}未通过')
        if c.get('gate') in ('G2', 'G3', 'G1 Python'):
            count = c.get('executed')
            if type(count) is not int or count <= 0:
                errors.append(f'{check_key(c)}缺少实际计数')
        if c.get('gate') == 'G2' and (type(c.get('expected')) is not int or c.get('executed') != c['expected']):
            errors.append('G2少执行或多执行')
        if c.get('gate') == 'G3' and c.get('complete') is not True:
            errors.append('G3未完成')
    for command in summary.get('commands', []):
        if command.get('exit_code') != 0 or command.get('timed_out'):
            errors.append('子命令失败或超时：' + json.dumps(command.get('argv'), ensure_ascii=False))
    return errors


def stable_content(start, end):
    fields = ('schema', 'scope', 'sha', 'head_tree', 'full_sha256', 'scoped_sha256',
              'commit_scoped_sha256', 'tracked_diff_sha256', 'staged_diff_sha256',
              'unstaged_diff_sha256', 'status_sha256')
    return bool(start and end) and all(start.get(k) == end.get(k) for k in fields)


def compare(root, git, *, source_ref=None, source_summary=None, target_ref='HEAD'):
    """A content eligibility verdict; never skips gates or grants merge authorization."""
    result = {'reusable': False, 'scope': list(SCOPE), 'changed_paths': [], 'non_record_changes': []}
    try:
        if source_summary is not None:
            errors = validation_errors(source_summary)
            if errors:
                raise ValueError('；'.join(errors))
            start, end = source_summary.get('content', {}), source_summary.get('content_end', {})
            if not isinstance(start, dict) or not isinstance(end, dict):
                raise ValueError('内容快照格式无效')
            if source_summary.get('mode') == 'env' or not source_summary.get('checks'):
                errors.append('环境探测不是门禁证据')
            if source_summary.get('dirty') is not False or start.get('dirty') is not False or end.get('dirty') is not False:
                errors.append('不干净的运行不能作为复用来源')
            if source_summary.get('content_stable') is not True or not stable_content(start, end):
                errors.append('运行期间内容不稳定或缺少内容快照')
            if start.get('schema') != 1 or start.get('scope') != SCOPE:
                errors.append('指纹版本或排除范围不兼容')
            if errors:
                raise ValueError('；'.join(errors))
            source_ref = source_summary.get('sha')
            if not source_ref:
                raise ValueError('源摘要缺少SHA')
        if not source_ref:
            raise ValueError('必须指定来源提交或摘要')
        source, source_tree, left = commit_manifest(root, git, source_ref)
        target, target_tree, right = commit_manifest(root, git, target_ref)
        result.update(source_sha=source, target_sha=target, source_tree=source_tree, target_tree=target_tree)
        if source_summary is not None:
            if start.get('sha') != source or start.get('head_tree') != source_tree or start.get('commit_scoped_sha256') != manifest_digest(left, True):
                raise ValueError('源摘要与来源提交内容不匹配')
        if target == git_bytes(root, git, 'rev-parse', 'HEAD').decode().strip():
            if git_bytes(root, git, 'status', '--porcelain=v1', '-z', '--untracked-files=all'):
                raise ValueError('当前目标工作区不干净，不能用提交代替工作区内容')
        left_map, right_map = {r['path']: r for r in left}, {r['path']: r for r in right}
        changed = sorted(p for p in left_map.keys() | right_map.keys() if left_map.get(p) != right_map.get(p))
        non_records = [p for p in changed if not record_path(p)]
        result.update(changed_paths=changed, non_record_changes=non_records,
                      source_fingerprint=manifest_digest(left, True), target_fingerprint=manifest_digest(right, True))
        result['reusable'] = not non_records
        result['reason'] = ('可复用：内容条件满足；' +
                            ('仅限源摘要已通过的关卡' if source_summary is not None else '提交比较不证明门禁曾通过，仍须有效源摘要') +
                            '；工具、参数与外部依赖仍须核对一致' if not non_records else '不可复用：存在非记录路径变化')
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        result['reason'] = '不可复用：' + str(error)
    return result


def inline(value):
    return str(value).replace('\n', ' / ').replace('\r', '').replace('`', "'")


def render(summary):
    errors = validation_errors(summary)
    passed = not errors
    lines = ['<!-- run_checks evidence v1 -->',
             f'总结果：**{"通过" if passed else "不通过"}**；模式：`{inline(summary.get("mode"))}`。',
             f'被测SHA：`{inline(summary.get("sha"))}`；工作区：`{inline(summary.get("root"))}`。',
             f'工作区状态：**{"干净" if summary.get("dirty") is False else "非干净运行（或状态未知），不能作为复用来源"}**。',
             f'开始：{inline(summary.get("started_utc"))}；结束：{inline(summary.get("finished_utc"))}。', '',
             f'入口命令（JSON参数数组）：`{inline(json.dumps(summary.get("invocation"), ensure_ascii=False))}`。',
             '检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：']
    actual = {check_key(c): c for c in summary.get('checks', [])}
    for key in summary.get('planned_checks', []):
        c = actual.get(key)
        if not c:
            lines.append(f'- {inline(key)}：未完成，**不通过**。')
        else:
            count = c.get('executed', '未单独统计')
            expected = c.get('expected', 'unittest发现数（未独立枚举）' if c.get('gate') in ('G3', 'G1 Python') else '专项执行')
            lines.append(f'- {inline(key)}：实际{count} / 预期{expected}；完整={c.get("complete", c.get("passed"))}；通过={c.get("passed")}。')
    if not summary.get('planned_checks'):
        lines.append('- 无测试关卡。')
    lines.extend(['', '工具版本：'])
    for name, tool in summary.get('tools', {}).items():
        lines.append(f'- {name}：`{inline(tool.get("version"))}`；`{inline(tool.get("path"))}`。')
    content = summary.get('content') or {}
    lines.extend(['', f'提交树：`{content.get("head_tree")}`；指纹范围：`{inline(content.get("scope"))}`。',
                  f'已提交范围指纹：`{content.get("commit_scoped_sha256")}`；工作区范围指纹（原始字节）：`{content.get("scoped_sha256")}`。',
                  f'全工作区指纹：`{content.get("full_sha256")}`；运行前后内容稳定：`{summary.get("content_stable")}`。',
                  f'已跟踪总diff SHA256：`{content.get("tracked_diff_sha256")}`；暂存diff：`{content.get("staged_diff_sha256")}`；未暂存diff：`{content.get("unstaged_diff_sha256")}`。'])
    for row in content.get('untracked', []):
        lines.append(f'- 未跟踪 `{inline(row["path"])}` SHA256：`{row["sha256"]}`。')
    lines.extend(['', '实际命令与日志（参数为JSON数组）：'])
    for command in summary.get('commands', []):
        lines.append(f'- `{inline(json.dumps(command.get("argv"), ensure_ascii=False))}`；退出={command.get("exit_code")}；耗时={command.get("seconds")}秒；超时={command.get("timed_out", False)}；日志=`{inline(command.get("log"))}`；SHA256=`{command.get("log_sha256")}`。')
    for c in summary.get('checks', []):
        if c.get('report'):
            lines.append(f'- 报告 `{inline(c["report"])}` SHA256=`{c.get("sha256")}`。')
    lines.extend(['', '失败清单：' + ('；'.join(inline(e) for e in errors) if errors else '无。'),
                  '失败归因：未提供基线失败证据，不自动区分旧失败与新失败。',
                  '复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；另核对工具、命令和外部依赖。'])
    return '\n'.join(lines) + '\n'


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument('--git', default='git')
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument('--source-ref')
    source.add_argument('--source-summary', type=Path)
    parser.add_argument('--target-ref', default='HEAD')
    args = parser.parse_args(argv)
    try:
        summary = json.loads(args.source_summary.read_text(encoding='utf-8')) if args.source_summary else None
        result = compare(args.root.resolve(), args.git, source_ref=args.source_ref, source_summary=summary, target_ref=args.target_ref)
    except (OSError, ValueError) as error:
        result = {'reusable': False, 'reason': '不可复用：' + str(error)}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result['reusable'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
