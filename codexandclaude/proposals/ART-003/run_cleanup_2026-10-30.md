# ART-003 跑步废案清理交接

日期：2026-10-30（用户当地日期）｜执行：Codex｜依据：用户在会话中直接要求清理主目录，并补充确认移除 `scripts/build_phf_run12.py`。

## 用户决定与停止条件

- `run_12_v1`、`run_12_v2`、`run_12_v3` 均未通过用户验收，全部作废；技术测试通过不代表美术认可。
- v1 已入库素材保持原样，由 Claude 在下一批规划任务中标为“废案（用户未通过）”；本次不修改 v1 素材、README 状态、任务板或规划。
- 第十二批 ART-003 任务卡获用户批准之前，停止制作新的跑步及其他动作帧。

## 本次清理范围

- 移除未提交目录 `phf/run_12_v2/`、`phf/run_12_v3/`，不将素材加入 Git。
- 移除五个脚本：`scripts/build_phf_run12.py`、`scripts/build_phf_run12_v2.py`、`scripts/export_phf_run12_v2.cjs`、`scripts/build_phf_run12_v3.cjs`、`scripts/package_phf_run12_v3.py`。其中仅 v1 脚本原先已入库，删除记录由本次 commit 追踪。
- 移除三个未提交测试：`tests/test_phf_run12_v2.py`、`tests/test_phf_run12_v3.cjs`、`tests/test_phf_run12_v3.py`。
- 将 `phf/README.md` 的未提交修改恢复至清理前 HEAD；该版本仍将 v1 写为待验收，Claude 后续规划时统一修正。
- 在 `tests/test_phf_index.py` 增加废案目录、五个脚本及三个测试均已移除的回归检查，保留 v1 原有技术检查。

## 验证与回滚

被测基线：`94a4a1f09524655b070f2e4b8f65d479f930a23a` 加本次清理、测试与交接记录。工作区原有 `.claude/` 本地配置不纳入提交。

- 命令：`python codexandclaude/tools/run_checks.py focused --python-all`。
- G3：`tests/` 188 项、`codexandclaude/tests/` 83 项，全部通过；检查期间内容稳定。
- 工具：Python 3.12.14、openpyxl 3.1.5、Node v24.22.1、Git 2.56.0.windows.2。
- 另检查 `git diff --check`，并核对 `phf/README.md` 与 `phf/run_12_v1/` 相对基线无差异。
- 本次仅清理废案及记录，不涉及游戏运行逻辑，不生成任何动作帧。

已入库脚本、测试与记录可通过对应 commit 的 `git revert` 回滚；未提交的 v2/v3 文件未进入 Git，无法通过该 commit 恢复。
