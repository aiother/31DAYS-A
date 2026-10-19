# 可直接交给 Claude 的首轮任务

请对《末日前31天》仓库做一轮只读审查，重点核对当前实现、已确认规则和测试证据是否一致。先阅读 `CLAUDE.md`、`Agents.md`、`docs/claude_collaboration.md` 和 `game/README.md`。

## 执行边界

1. 记录当前 HEAD、分支及 `git status --short`。报告审查的是提交态还是包含本地修改的工作区；发现本地差异时单独标记。
2. 本轮只读，不编辑文件、不生成资源、不运行会写入工程或存档的测试、不创建 commit。可以阅读测试和既有报告；需要动态复现时提供命令和所需环境，交给实施者在隔离环境运行。
3. 不新增玩法、数值、正式美术或完整装备等冻结范围以外内容。历史阶段记录须结合最新追加修订阅读，不凭早期“尚未实现”字样直接判缺陷。
4. 优先检查下面三条链路，每条最多报告三个有证据的问题；未发现问题也明确写出覆盖范围。其他高风险发现可以单独列出。

## 优先审查链路

| 链路 | 重点 | 入口 |
| --- | --- | --- |
| 日期与救助 | 跨日、第三日超时、救助过期、重试与旧档迁移是否一致 | `game/docs/day_clock_implementation.md`、`game/docs/world_day_rules_implementation.md` |
| 持久资源 | 药包/珍珠/成长的保存失败回滚、重复领取、死亡保留及槽隔离 | `game/docs/medkit_implementation.md`、`game/docs/pearl_growth_implementation.md`、`game/docs/combat_growth_implementation.md` |
| 验收证据 | 连续主线、专项测试与报告的覆盖边界；自动化未覆盖的人工操作 | `game/docs/campaign_acceptance.md`、`scripts/verify_game.py`、`tests/test_verification_runner.py` |

根据入口继续追踪实际生产代码与对应 `game/tests/`，避免仅审文档。T6/T7 工作区已有修改且确认状态未知，不据此自行补全需求。

## 回报格式

先给整体判断，再逐项列出：严重程度、文件路径与行号、触发条件、预期和实际、最小复现步骤、对应规则来源、现有测试缺口、建议的最小修复范围。明确区分源码推断、已运行验证和未验证。

最后列出实际阅读文件、未覆盖范围、需要用户裁决的具体规则冲突，以及建议先实施的一项任务。没有证据时写“待验证”，不要为凑数量报告缺陷。请把报告返回用户，由用户转交当前 Codex 会话复核。
