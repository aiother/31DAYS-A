# PLN-002 交付记录：规划刷新（第八、九批收尾）

状态：已交付，待 Codex 审查｜实现：Claude｜日期：2026-10-25

## 固定对象

- 基线：master `d8fb7b9f690fb57b5bb1e73c03b5aabb167a61f6`（第十批规划合入后）。三份规划文档的汇总基线统一为 master@d8fb7b9。
- 实现提交：`8ba29c699108d4b5b4ced08adc864b60d28a3707`（分支 `claude/PLN-002`），只改 `codexandclaude/ROADMAP.md`、`BACKLOG.md`、`BOARD.md`。
- 刷新时 SYS-012 已复审通过、用户 G4 通过并授权合入，但尚未进入 master；快照把它写作“已复审通过、待集成”，没有当作已完成。

## 改动

- **路线图**：
  - 首部与快照说明：补“第九批完成后由 PLN-002 按 master@d8fb7b9 刷新”。
  - 快照重写五行：美术（SYS-010 动画接入框架、FX-001 正式战斗特效，FX-002 进行中）、音频（SYS-011 事件框架、强弱前摇分槽、A/B 级空槽、两条总线）、文本与演出（SYS-012 待集成）、测试（95 个套件 + 导入与主场景共 97 项，Python 110 + 67；记录两次偶发的退出泄漏）、规格（T0～T3 现行，T4 进行中，T5 系列待改写并含跨文档遗留）。
  - M3、M4 的依赖说明改为已完成 / 第十批 / 等待素材三类；P3 列表补 BL-121～BL-125；“需要用户决定的事项”中美术资源一行的建议时间改为“现在”（第十批完成后，M3 不依赖素材的工作基本做完）。
  - 变更记录加一行。
- **待办清单**：状态变更与新增见下表。
- **任务板**：首部改为“第八、九批全部完成，第十批进行中；汇总基线 master@d8fb7b9”；各任务行核对无误，不需改动。

## 状态变更表

| 待办 | 原状态 | 新状态 | 依据 |
| --- | --- | --- | --- |
| BL-023 | 已立项 DOC-009（第九批） | 已完成（DOC-009） | DOC-009 集成记录（master@091d701） |
| BL-066 | 已立项 SYS-011（第九批；事件框架与占位音，正式音频待用户提供） | 待立项（系统部分已完成：SYS-011 事件框架、占位音、强弱前摇提示；正式音频待用户提供） | SYS-011 集成记录（master@6af7804）；正式音频仍需用户提供，事项不关闭 |
| BL-025 | 待立项 | 待立项（事项说明扩充） | 并入 DOC-008、DOC-009 跨文档清单中属于 T5 系列的四处旧表述，以及 SYS-012 第1轮审查 N1 的开场写盘失败处理 |

核对后不变：BL-022（已完成 DOC-008）、BL-060（已完成 SYS-010）、BL-024（已立项 DOC-010）、BL-065（已立项 FX-002，战斗部分 FX-001 已完成）、BL-081（已立项 SYS-012）、BL-117／BL-118（待用户决定）以及其余 P3 观察项。

## 新增事项表

| 编号 | 优先级 | 事项 | 来源 |
| --- | --- | --- | --- |
| BL-121 | P3 | 攻速类增益缩短顿帧（完整版方向；V0.1 保持 0.10 秒） | 用户 2026-10-24 FX-001 G4 |
| BL-122 | P3 | 正式门音接入时拆分 `interaction.gate` | SYS-011 第1轮审查 N3 |
| BL-123 | P3 | T7 核对表死亡界面旧口径、T1 变更记录未记 DOC-009 引用修正 | DOC-009 跨文档清单 |
| BL-124 | P3 | SYS-010 验收入口复用前的两处修补（观察中） | SYS-010 用户 G4 观察 |
| BL-125 | P3 | SYS-012 兼容属性日后移除 | SYS-012 第1轮审查 N2 |

优先级理由：五项都不影响 V0.1 的规则或验收；BL-121 是完整版玩法方向，其余为小修补或技术债，随相关任务处理即可，所以都列为 P3，不进入里程碑。

## 检查

实现提交上起点干净执行 `focused --python-all`：**通过**，G3 **110/110 + 67/67**，content_stable=True。其中协作检查覆盖：三份文档基线一致、路线图覆盖全部未完成 P1/P2 待办、待办格式与状态写法、快照音频行。摘要 `codexandclaude/runs/20261025T084823.662372Z/`（不入库）。

<!-- G3 自动摘要 -->
<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`8ba29c699108d4b5b4ced08adc864b60d28a3707`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-25T08:48:23.662372+00:00；结束：2026-10-25T08:48:47.744259+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际110 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`e39afeb60d421f6b57f5145a39811a22cb101c77`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`690b28b8ec17cce17875891d4793dac8d37ef8790c3ac2509c682a2424426fb1`；工作区范围指纹（原始字节）：`442ba3d5052db9005b8456f533186646e9c70e55d81437a496048c3274e29fd1`。
全工作区指纹：`b8eee505d9697fb2a70159eae416619a52902ea90f1fb291d9a39ac9000487ce`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T084823.662372Z\001.txt`；SHA256=`808987f9548a227869deb552b4765fca641daba9e792e63a849ee0bdf2adf693`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T084823.662372Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.343秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T084823.662372Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T084823.662372Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T084823.662372Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.204秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T084823.662372Z\006.txt`；SHA256=`a0853b78c49f7efff54a037d23b04ab62bef69ad8a9d2f11e0b820d80a6932f2`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.968秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T084823.662372Z\007.txt`；SHA256=`6bbe8c0397d03c7c69e6ace3e5f01bd46ec7dfc2c07a0dd8ddac11871742371c`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
