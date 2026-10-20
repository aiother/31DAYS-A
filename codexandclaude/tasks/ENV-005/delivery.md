# ENV-005 交付记录

日期：2026-10-20｜实现：Codex｜审查：Claude｜分支：codex/ENV-005

## 固定提交与范围

- 基线：master@43e7dc2a5c8f9376b9b28db9053ebfddd6ed9c46，规划已按用户授权从07cb0cc快进合入；master规划后G3为102/102 + 46/46，干净运行，证据目录20261020T140638.054508Z（主目录runs）。没有修改两张规划卡在master上的首部。
- 实现SHA：`a3bc05e74ed9af67b329b729e280ad561f078803`，包含初始实现2a35e35及起止内容漂移处理修订。最终完整检查固定此SHA，非干净先测再提交的证据不充当最终门禁。
- 修改：tools/run_checks.py；新增同目录check_evidence.py；tests/test_run_checks.py；新增tests/test_check_evidence.py；env.md；ENV-005任务卡首部。交付提交只新增本文件，不修改其他文件或task.md。
- 不修改游戏、verify_game.py、套件登记、BOARD/BACKLOG/ROADMAP、EXP-002或协作规范。原有summary.json字段保留，只增加证据及内容身份字段。G4不需要。

## 实现与复现

原入口没有evidence.md、脏内容哈希、范围指纹或复用判断。先新增真实临时Git仓库测试，初次因缺少check_evidence.py失败；实现后专项40/40、G3 102/102 + 61/61通过。15个新增测试覆盖真实Git脏diff/未跟踪字节、暂存改名及删除、精确记录排除、代码/规格/任务卡差异、无效/不完整/脏来源、缺汇总、起止漂移与摘要失败路径；原模式编排测试均保留。

G1命令：`python -m unittest codexandclaude.tests.test_run_checks codexandclaude.tests.test_check_evidence`，40/40；原卡单独test_run_checks为27项。证据：runs/env005-final-g1.txt。

每次env/focused/full在原summary.json旁生成evidence.md，人手复制，不自动改记录或提交。起止快照保存Git树、提交范围指纹、原始工作区指纹、三种diff哈希及所有未跟踪文件内容哈希。提交blob和CRLF/LFS检出字节分别记录；指纹不是运行期间每次瞬时写入的监控。

默认仅排除runs及任务目录下delivery/review/integration/acceptance四类记录；task.md、proposal.md、配置、规格、代码与测试仍参与比较。不允许任意扩大范围。比较只证明内容条件，脏/不稳定/失败/缺最终汇总的来源一律不能复用；env成功也不能冒充门禁。工具、参数与外部依赖仍由使用者核对一致，不能核对则重跑。详见env.md。

## 最终full原样自动摘要

以下段落直接读取工具生成的evidence.md，未手抄或重算门禁计数：

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`a3bc05e74ed9af67b329b729e280ad561f078803`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-20T14:21:47.717485+00:00；结束：2026-10-20T14:34:23.282120+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际76 / 预期76；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际61 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`41d3d90ceaf2642bf177ef3d234b4caa7b05f80f`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`db9ec312066fa4089201be7c618c27418f021b3a1c562d9bc9ade9ebc5db1951`；工作区范围指纹（原始字节）：`052e85ba9ff215ba5089274b2325fc644a29b9a5272e28d037e4f646c411176e`。
全工作区指纹：`291acfc838a7b55543ee9e5885703e8ac3b58ebaa62a08f6c3bac17ab74f9e32`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261020T142147.717485Z\001.txt`；SHA256=`a903f6d6f3e178d7c118cbfa8d6f78336875bbf00e137dbf0a929d390ae1e9be`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261020T142147.717485Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261020T142147.717485Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261020T142147.717485Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261020T142147.717485Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261020T142147.717485Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261020T142147.717485Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=742.594秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261020T142147.717485Z\007.txt`；SHA256=`727285f75d558381bb5ff344b99899ebd88648f32b2635a915f003bd7085fb52`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.219秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261020T142147.717485Z\008.txt`；SHA256=`894b24720eaaec4bc521eab00b1f3d021acc544efec22b5c6f5f17fc714bf2ba`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=8.421秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261020T142147.717485Z\009.txt`；SHA256=`8b80e6192637277044379273bf6f80420b05f6944459ab67fda1bd523a3da709`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261020T142147.717485Z\engine.txt` SHA256=`1c3b9d515a43010fd5309a39d75f4e137875bedd193c1c22795111f76cc12841`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；另核对工具、命令和外部依赖。

## 变异检查

用本次最终full原始摘要的副本执行，不修改正式摘要；前三项改字段，第四项比较本任务两个真实实现提交。结果如下（工具输出提取）：

- one_gate_item_missing：不可复用：G2少执行或多执行。
- final_summary_missing：不可复用：缺少最终汇总。
- dirty_source：不可复用：不干净的运行不能作为复用来源。
- non_record_code_differs：不可复用：存在非记录路径变化。

复现前三项：复制本次summary.json，分别将checks[0].executed减1、删除finalized、将dirty设true，再传给check_evidence.py --source-summary。前两项的render也必须为“不通过”；脏来源可以保留实际检查通过结果，但必须“不可复用”。完整复现脚本/输出保留于忽略的runs/env005-probe.py、env005-final-mutations.json。入库回归测试为test_mutations_missing_final_incomplete_gate_dirty_source_and_code_are_rejected；原有G2解析测试另外验证少一条PASS、重复PASS或缺最终汇总均失败。

代码变化的真实提交复现：

```powershell
python codexandclaude/tools/check_evidence.py --source-ref 2a35e35e96af8b0abcb89a13a748a57d2e118cf0 --target-ref a3bc05e74ed9af67b329b729e280ad561f078803
```

输出不可复用、退出1，非记录变化为env.md、test_run_checks.py、check_evidence.py、run_checks.py；提交范围指纹从fc5dd2503fd193c4582a55018b3ef6906ea7377adf6903fc8b7cc752f21dbdfe变为db9ec312066fa4089201be7c618c27418f021b3a1c562d9bc9ade9ebc5db1951。真实脏自测摘要20261020T141428.420756Z也被单独拒绝；不存在summary文件时退出1，不能生成看似可复用的结论。

## 本交付的记录复用演示

最终实现到本交付HEAD仅新增此delivery.md。交付提交落地后核验以下两条命令；两者均应输出reusable=true、non_record_changes=[]、相同范围指纹db9ec312066fa4089201be7c618c27418f021b3a1c562d9bc9ade9ebc5db1951：

```powershell
python codexandclaude/tools/check_evidence.py --source-ref a3bc05e74ed9af67b329b729e280ad561f078803 --target-ref HEAD
python codexandclaude/tools/check_evidence.py --source-summary codexandclaude/runs/20261020T142147.717485Z/summary.json --target-ref HEAD
```

这是同一主机、同一工具与参数下的记录提交，比较不自动跳过门禁；交付后仍独立跑一次focused --python-all验证本记录链接。交付自身SHA不写入自身文件，由会话交接给出；比较输出保留在runs/env005-delivery-ref-reuse.json、env005-delivery-summary-reuse.json。

## 脏字节证据样例（早期自测，不代替最终门禁）

20261020T141428.420756Z是在基线SHA上、首版实现尚未提交时的真实脏运行；摘要加粗标明非干净运行，内容字段如下，源比较已拒绝。此处仅演示已跟踪diff及未跟踪字节均有身份，最终实现使用上面的干净full结果：

```json
{
  "tracked_diff_sha256": "cf85a89ff524674ee9342d5985fefb93775fe0afb6371250b500befea9eddbfc",
  "staged_diff_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "unstaged_diff_sha256": "cf85a89ff524674ee9342d5985fefb93775fe0afb6371250b500befea9eddbfc",
  "untracked": [
    {
      "path": "codexandclaude/tests/test_check_evidence.py",
      "mode": "100644",
      "sha256": "1951c3848c003bbe2f2244710f4bd2ec65d4e147ed0105de9246a152c27fe80f"
    },
    {
      "path": "codexandclaude/tools/check_evidence.py",
      "mode": "100644",
      "sha256": "faf29a38d294b41b63e601bcd82eeb76f5e109c387df3e6ff31bf2e88363ce90"
    }
  ]
}
```

## 需要审查者留意

1. Python预期数标注为unittest发现数、未独立枚举；不把观察到的计数冒充另一个独立预期。原有门禁判定不变，G2仍核对完整登记集合；少执行变异同时覆盖G2实际报告和汇总字段。
2. 原始字节起止快照用于复用资格，与检查实际通过结果分开。Godot导入曾生成两份SVG.import的纯换行差异，确认git diff --ignore-space-at-eol为空后按env.md恢复，未提交生成物；最终full起止快照相同且均干净。默认不替用户恢复文件，起止漂移时只能保留检查结果、不能复用。
3. 首版full（20261020T141502.122813Z）在修订期间被主动停止，保留失败汇总，不计为通过；本交付只有a3bc05e上的最终full作为完整门禁。没有绕过测试、降低通过标准或修改游戏测试。
4. Git引用比较本身不证明已有成功测试；摘要比较才校验成功/完整/干净/稳定的来源。被排除Markdown记录的正确性仍需人工或G3检查，不由代码内容指纹证明。

未合入master。请Claude固定交付SHA审查，先确认实现到交付只有本记录变化，复现四类拒绝及只改记录的正例；G4不需要。
