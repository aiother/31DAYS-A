# PLN-002 第1轮审查

审查者：Codex｜日期：2026-10-25｜结论：**通过，无阻断项**。两条非阻断建议见下文。未修改 Claude 实现或规划文档，未合并 master。

## 固定对象与范围

- 基线：`d8fb7b9f690fb57b5bb1e73c03b5aabb167a61f6`。
- 实现：`8ba29c699108d4b5b4ced08adc864b60d28a3707`；交付：`2e821bd1b31a379583317733ab22226bf287d9f6`。
- 独立工作区先执行 `git switch --detach 2e821bd1b31a379583317733ab22226bf287d9f6` 固定审查与 G3，再从该点建立 `codex/PLN-002-review`，只提交本记录。
- 基线到实现净改动只含 ROADMAP、BACKLOG、BOARD；实现到交付只新增 delivery.md 与更改任务卡首部。无 Words、游戏代码、测试或规则改动。

## 状态、基线与快照核对

1. 三份规划文档汇总基线均为 master@d8fb7b9，与本任务固定基线一致，不要求随之后每次集成自动推进基线。
2. 对 BACKLOG 新旧表逐项比较，真正改变状态的只有 BL-023 与 BL-066，新增 ID 恰为 BL-121～BL-125。BL-025 是事项描述扩充，状态仍为待立项；交付表也明确说明这一点，没有伪称立项或完成。
3. BL-023 的“已完成（DOC-009）”由 DOC-009 任务卡、两轮审查与集成记录支持，收尾 master@091d701。BL-066 把已完成的 SYS-011 框架 / 占位 / 强弱前摇，与尚需正式音频的余项分开，不把整个事项关闭；依据 SYS-011 集成记录，成立。
4. 只读核对 BOARD 所有已完成行与相应任务卡首部，无不一致；第八、九批全部完成有各自集成记录支持。未把第十批其余任务提前关闭。
5. 快照的 SYS-010 动画框架、FX-001 战斗反馈与 0.10 秒顿帧、SYS-011 统一事件 / 强弱音高与音量总线均有基线代码和交付依据。正式角色 / 环境资源与台词仍未到位，没有误标正式资源完成。音频概括的一处例外见 N1。
6. 实际导入基线 `scripts/verify_game.py` 的套件发现器，枚举为 **95 个套件 + 导入 / 主场景 2 项 = 97 项**；与快照一致。本次 G3 独立发现 **110 + 67**。UI_DATA / PURSUIT_SURVEY_A 偶发退出泄漏的说法有 FX-001 修复交付记录支持，未将失败作为通过证据。
7. M3/M4 没有提前关闭：BL-060 / BL-022 / BL-023 已完成；BL-065 / BL-066 / BL-081 均区分已做部分和余项；BL-024 仍由 DOC-010 处理，BL-025 尚待立项。M3 依赖列的 BL-063 说明可补全，见 N2。

SYS-012 的“已复审通过、待集成”按本次固定刷新基线及交付的并行进展说明处理，不视为误关事项。审查时当前 master 已在 `300d5d978d9e3acdabde5d66465629f9b341e81d` 完成 SYS-012 集成；今后合入本规划时应保留 master 的 SYS-012 已完成状态，不能回退。此为后续集成提示，不要求本分支追逐更新汇总基线。

## BL-025 与新增事项

| 事项 | 核对结论 |
| --- | --- |
| BL-025 | 原有 T5～T5.4 改写范围、B-012～B-023 / B-027 均保留。新增 T5.4 §7 救场旧未决、§6.3 威胁单位、自然日期不会判 NPC 失救旧句，以及 T5.3 的 10 旧前后摇 / 一轮协同战四处问题，对应 DOC-008、DOC-009 跨文档清单；SYS-012 开场失败保持锁定、E/RB 重试也已写明，未遗漏要求登记的 T5 系列项。T4 的相应矛盾已明确写入 DOC-010 任务卡与 BL-024 所引 B-005，不必重复立项 |
| BL-121 | 与 FX-001 G4 用户决定一致：V0.1 基础顿帧仍为 0.10 秒，攻速增益缩短留在完整版，0.08 秒仅为试验 / 后续例子；配置字段确为 CombatEffectConfig.hit_stop_seconds。P3、V0.1 之后合理，不越权落地增益规则 |
| BL-122 | 对应 SYS-011 首轮 N3 与复审保留说明；普通 Room 通行复用 interaction.gate，正式门音接入时再拆分，P3 合理 |
| BL-123 | T7 核对表死亡菜单原三项引用、T1 两处引用修正未另加变更行均仍存在，并由 DOC-009 清单提出；P3 后续补注合理，不改变 A-014 四项已裁决结论 |
| BL-124 | 与 SYS-010 G4 两处验收入口现象一致；FX-001 已去除按余额差猜获得的光圈，条目明确不再声称该画面问题仍存在。复用入口前修余额信号与 Hurtbox、列为观察中，不扩成正式游戏缺陷 |
| BL-125 | 对应 SYS-012 N2；兼容 setter 的副作用与日后显式接口迁移 / 移除记为技术债。N3 单实例约定已由 SYS-012 接入说明补明，不需另造缺陷 |

新增五项未代用户裁决；BL-117 / BL-118 等待用户决定项保留，P3 清单收录五项且未挤入当前里程碑。任务卡要求登记的来源均有去向。

## 非阻断建议

- **N1（ROADMAP.md:25）**：音频快照将“可能性音效（A 级）”整体概括为空槽，略过了恢复音例外。`default_audio_map.tres` 的 heal.start / heal.done 虽然 clips 为 null，但同时列在 placeholders，`AudioEvents.play()` 实际生成占位音；`game/docs/audio_events.md` 已标为“A 级，暂用占位”。可改成“获得 / 消耗 / 不足音留空，恢复音暂用占位；正式 A 级音频仍待资源”。BL-066 已正确保持未完成，因此不影响本次状态关闭与分工，非阻断。
- **N2（ROADMAP.md:38）**：M3“包含事项”仍列 BL-063，BACKLOG 也保持其待立项，但依赖栏的“其余事项等待用户素材”枚举漏了它。建议补明角色比例规范随角色素材接入核对，或可先做哪部分尺寸约定，避免后续安排只照依赖栏而漏排。事项并未从 M3 / BACKLOG 消失，非阻断。

## 独立验证

固定交付 SHA 上执行 `python codexandclaude/tools/run_checks.py focused --python-all`：**G3 110/110 + 67/67 通过**，起止干净、content_stable=True，未跳过测试。纯规划文档按矩阵不需要 G2。本轮没有代码 / 规则修复，不制造无关代码变异；另以只读表差异、全部已完成任务卡状态及真实套件枚举核对内容。审查记录提交后补跑 G3，结果随最终回报。

原始摘要：`codexandclaude/runs/20261025T091904.992880Z/summary.json`（不入库）。

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`2e821bd1b31a379583317733ab22226bf287d9f6`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-25T09:19:04.993879+00:00；结束：2026-10-25T09:19:21.458232+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际110 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`9e9d61a802311817bcf6184fffdadb807caf29b4`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`41a72491752db9a761f8a13ebed36e121e856e3928af46c6587132d302a0305f`；工作区范围指纹（原始字节）：`d3824dfeb244fba37824cd00b4ed9c06487f4d3a9834de05d48ea1b43f0e523a`。
全工作区指纹：`6d190bd3578cd057468237de02a057ecf5ccf43a59f9f5d625e0a1037af333d1`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T091904.992880Z\001.txt`；SHA256=`e869dbcb6975b6529c44ad106cc5d7bd8e014b019d9123c397f9daa9571200da`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T091904.992880Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T091904.992880Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T091904.992880Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T091904.992880Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.312秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T091904.992880Z\006.txt`；SHA256=`5e7028a6efc10a65e1647bc72cc1510e8e6cf66cb0c91e57107c3a7dd86fe12c`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.688秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T091904.992880Z\007.txt`；SHA256=`b8732369f901343c17dedf2c03dc256cd410dcd7eee8c0b80d96cc6c46453566`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
