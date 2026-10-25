# SYS-012 集成记录

日期：2026-10-25（America/Los_Angeles）｜集成者：Codex｜状态：已完成。

## 授权与固定合入

用户本轮明确“用户 G4 实机走查通过，授权合入 SYS-012”，指定固定复审提交 `893218a40557de375ca81087c9ff8769c6712280`。本次合入在该授权之后执行。

- 合入前 master：`d8fb7b9f690fb57b5bb1e73c03b5aabb167a61f6`，是目标的祖先；未有重叠的用户未提交改动，`game/project.godot` 无本地修改。
- 主目录的 `.claude/settings.local.json` 按既有全局 Git 规则忽略，本次未暂存、清理、移动或修改。门禁实际运行环境下 Git 状态干净；受限读取无法访问全局 ignore 时会把该路径列作未跟踪，不代表本次新增文件。
- 执行 `git merge --ff-only 893218a40557de375ca81087c9ff8769c6712280`，无冲突。快进后的 master / 集成被测目标即此 SHA，无独立合并提交；没有合并可移动分支名。
- 目标保留实现 `650067a` / `f189140`、R1 修正 `1ef4c71`、交付 `ede964f`、首轮审查与复审、用户 G4 结果。已将最终 review.md 与首轮 `d12f8dc` 按原始 Git 内容比较：首轮全文为最终文件前缀，净变化只追加复审与 G4。历史 `6ea2542` 的误覆盖已由 `c89b3fa` 恢复，没有丢失首轮内容。

## G4 与范围

用户已于 2026-10-25 在复审分支上以正常游戏实机走查各段演出，原话“没问题，合并吧”，记录见 [review.md](review.md) 第2轮末尾 G4 节；本轮会话再次确认通过并授权。

本次不改演出内容、目录策略、输入、奖励、日期、波次、存档或游戏代码。N1（开场写盘失败保持锁定且可 E/RB 重试）由 PLN-002 登记；N2/N3 的兼容 setter 与单实例说明已随实现保留。

## master 门禁与证据复用

按 ENV-005，在快进后的 master 对固定目标比较：

```powershell
python codexandclaude/tools/check_evidence.py --source-summary D:/31days/codexandclaude/worktrees/codex/codexandclaude/runs/20261025T081331.107400Z/summary.json --target-ref HEAD
```

来源是 Codex 在修正实现 `1ef4c71771732641675dbf8983ba1ffbb3090286` 上的干净完整 full：G2 98/98、G3 110/110 + 67/67，起止干净、content_stable=True，CINEMATICS_TESTS 200/0，WARNING / ObjectDB 泄漏 0。原始摘要与日志保留在上述来源目录。

来源到固定合入目标仅 delivery.md / review.md 变化，非记录路径变化为空，范围指纹相同。比较结论 **G2 可复用，G3 须重跑**；顶层 reusable=false / 退出 1 是部分可复用的正常结果，不能冒充 G3 通过。已核对同机 Godot 4.7.2.stable.official.ed1daf0bf、相同 Python / Git / Node 路径与版本、full --jobs 4 及同一套项目依赖；项目路径只因工作区不同而变化，未变更本地配置或依赖。因此合入目标沿用该 G2，不另跑 full。

比较原始输出 `codexandclaude/runs/sys012-integration-reuse.json`：

```json
{
  "reusable": false,
  "scope": [
    "exclude codexandclaude/runs/**",
    "exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md"
  ],
  "changed_paths": [
    "codexandclaude/tasks/SYS-012/delivery.md",
    "codexandclaude/tasks/SYS-012/review.md"
  ],
  "non_record_changes": [],
  "gate_reuse": {
    "G2": {
      "reusable": true,
      "reason": "可复用：内容条件满足；仍须核对工具、参数和外部依赖"
    },
    "G3": {
      "reusable": false,
      "reason": "须重跑：记录变化会影响G3及其他非G2检查"
    }
  },
  "reusable_gates": [
    "G2"
  ],
  "rerun_gates": [
    "G3"
  ],
  "source_sha": "1ef4c71771732641675dbf8983ba1ffbb3090286",
  "target_sha": "893218a40557de375ca81087c9ff8769c6712280",
  "source_tree": "9f82beeb4a7f608171e4f6ec937ada21be10d4f6",
  "target_tree": "3f888287bae46b10cb3cdba74af7e88c4a81920f",
  "source_fingerprint": "a4456f3689b6ed3086dc5220999933364e1f10f94c26d2a7d7e59e17f1733d57",
  "target_fingerprint": "a4456f3689b6ed3086dc5220999933364e1f10f94c26d2a7d7e59e17f1733d57",
  "reason": "部分可复用：G2内容条件满足；记录变化，G3必须重跑；仅限有效源摘要已通过的关卡；工具、参数与外部依赖须核对一致"
}
```

在 master 实际重跑 `python codexandclaude/tools/run_checks.py focused --python-all`：G3 **110/110 + 67/67** 通过，起止干净、content_stable=True；摘要 `codexandclaude/runs/20261025T084717.136034Z/summary.json`。G2 复用比较仅针对合入目标 893218a，收尾的纯文档状态变化按矩阵另跑 G3，不声称最终收尾提交范围指纹仍与来源相同。

## 收尾

证据提交仅新增本 integration.md、将任务卡首部和 BOARD 的 SYS-012 行标为已完成。历史交付与首轮审查中的待审查 / G4 未进行表述作为过程记录保留，最终状态以复审 G4 节与本记录为准。提交后对最终收尾 SHA 另跑 G3，结果随最终回报给出。

BL-081 本次完成流程衔接部分，正式演出表现仍待后续；不关闭整个待办。BACKLOG / ROADMAP 与其他批次任务的刷新留给 PLN-002，汇总基线 master@519a7f6 保持不变。

## master G3 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`893218a40557de375ca81087c9ff8769c6712280`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-25T08:47:17.136034+00:00；结束：2026-10-25T08:47:34.094017+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际110 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`3f888287bae46b10cb3cdba74af7e88c4a81920f`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`a4456f3689b6ed3086dc5220999933364e1f10f94c26d2a7d7e59e17f1733d57`；工作区范围指纹（原始字节）：`bfbe7cb822bea0360ae27e6c28970ff14ec74495aef400222f21e240a57b2ad2`。
全工作区指纹：`dc490985ed1f616f70f686300ca0d7fa624e94207977e9b0994b4d89b0215ecd`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T084717.136034Z\001.txt`；SHA256=`e9a74340750713dc497f3336161d89e03842d4de894334223ad7bd462a7309f6`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T084717.136034Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.344秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T084717.136034Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T084717.136034Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T084717.136034Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.359秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T084717.136034Z\006.txt`；SHA256=`6d36d09eb93bbe7222e9645347fc79b04748fd45b52daceb0f041d760939717b`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=12.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T084717.136034Z\007.txt`；SHA256=`f9988cef8e5615f1e8d9bde5c072da3ddfc737e0508452b7a9f6b2be7ee7a8fd`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 复用的 G2 来源自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`1ef4c71771732641675dbf8983ba1ffbb3090286`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-25T08:13:31.107400+00:00；结束：2026-10-25T08:24:44.787806+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际98 / 预期98；完整=True；通过=True。
- G3:tests：实际110 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`9f82beeb4a7f608171e4f6ec937ada21be10d4f6`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`a4456f3689b6ed3086dc5220999933364e1f10f94c26d2a7d7e59e17f1733d57`；工作区范围指纹（原始字节）：`930123778aad06c3d8fe1b3c317b4d612737e9cce410ca70a2eb936dcf0cd0f7`。
全工作区指纹：`c1fd475f3348b8a9b83c477a20048bd6813ada65834f75901e9491bea1b36912`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T081331.107400Z\001.txt`；SHA256=`75069f33cb199689623eb6aa161e02a0a6ae4bf4cb834be7da038a11bbd21436`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T081331.107400Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T081331.107400Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.328秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T081331.107400Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T081331.107400Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T081331.107400Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261025T081331.107400Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=658.25秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T081331.107400Z\007.txt`；SHA256=`84bb3dc0d0cab2a3896b4bcb219c334e79af71b80b2741ce0fc3e1daed015022`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T081331.107400Z\008.txt`；SHA256=`042171eb799563e9e64b40213a999fd50948adf6b890a35b2f545874e17f8a6f`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.735秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T081331.107400Z\009.txt`；SHA256=`cfc6575da39c77ee2fa267f41f12ebb520bdfc11c218fde2ff509a9fb4c09936`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T081331.107400Z\engine.txt` SHA256=`5faae7d9ab363bf9f74fcdbc8d94dc36a42060a75d591325f2c08061d9617de8`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
