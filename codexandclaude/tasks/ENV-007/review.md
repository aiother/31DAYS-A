# ENV-007 审查记录

审查者：Claude｜日期：2026-10-22｜结论：**通过**（无阻断项；1 条非阻断建议）

## 固定对象

- 基线：`2f79b8311155826301509c0cb6c26691f4a1e2c9`
- 实现：`e431492b3d50be19cfc2192a12a7107cacd72252`
- 交付／被审 SHA：`b9b6d1304347f8950f28b47909c79bda186805a0`；审查分支 `claude/ENV-007-review` 只新增本记录。

## 范围

`game/prototypes/EXP-003/tests/` 两个 `.uid`（新增）、`scripts/verify_game.py`、`tests/test_verification_runner.py`、任务卡首部与交付记录，均在任务卡允许范围内；未改游戏代码。

## 要求逐条核对

| 要求 | 结果 |
| --- | --- |
| 1 内容稳定 | 成立。EXP-003 两个 `.uid` 入库；新增 G3 用例 `test_every_tracked_gd_has_a_tracked_uid` 核对 `game/` 下每个已跟踪 `.gd` 都有已跟踪 `.uid`，以后同类缺失会直接在 G3 报出。本机合并预演 full **content_stable=True**（此前本机每次都是 False） |
| 2 改名漏检 | 成立。`game/tests/` 下（`acceptance/` 除外）带登记首行或 `extends SceneTree` 而文件名不是 `test_*.gd` 的脚本，`discover_suites()` 报错并列出全部路径；继承测试基类的辅助脚本、验收适配不误报（各有用例） |
| 3 调度顺序 | 成立。按 `timeout` 降序、同值按路径提交；报告仍按路径排序（用例核对提交顺序与报告段落顺序） |
| 4 判定与证据格式不变 | 成立。通过 / 失败条件、`ERROR_MARKERS`、报告格式未改 |

## 独立检查

见 SYS-009 审查记录“独立检查”一节（两项在同一合并预演上检查）。ENV-007 相关：

| 变异（临时改 `scripts/verify_game.py`，跑 `tests.test_verification_runner`） | 结果 |
| --- | --- |
| 去掉改名检查 | 4 项失败，退出 1 |
| 调度恢复按路径顺序 | 1 项失败，退出 1 |

恢复原字节后该模块全部通过。

## 非阻断建议

N1：`test_every_tracked_gd_has_a_tracked_uid` 依赖 git 索引，只检查已跟踪的 `.gd`。新建脚本时只要 `.gd` 与 `.uid` 一起提交即可；建议在协作规范的提交说明里加一句“新增 GDScript 连同编辑器生成的 `.uid` 一起提交”，免得交付时才在 G3 发现。

## 结论

通过。可按 `b9b6d13` 合入 master；与 SYS-009 合入顺序不限，无冲突。
