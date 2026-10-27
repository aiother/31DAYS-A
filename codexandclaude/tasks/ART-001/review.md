# ART-001 审查

结论：**需修改**（一项 P2 交付缺口）。审查：Codex，2026-10-27。

基线：`9bed956bd6ebbe3ba35692fcb6810a6666e28439`；实现：`eed3d2f263603b6fdabfb063c2f204bbd657216a`；交付及被测 SHA：`e2978c27f4abfbc12a183468aabb89096ef1e508`。分支：`codex/ART-001-review`。

## 问题

- **[P2] 补齐玩家部件拆分清单。** `prompts/01_player_full.md` 只有全身设定图提示词与挑图要点；任务卡要求的“玩家的第一批提示词：全身设定图（正侧面）与部件拆分清单”没有完整交付。`asset_spec.md` 第 3 节给出通用骨骼树及附加骨骼，但没有列出定稿玩家的具体部件图片清单：斗篷与内衬如何分图、面纱与头部如何处理、兜帽和三段衣摆对应哪些文件、被遮挡的远侧肢体哪些需要补画。通用模板的 isolated body part 句子也没有指定具体部件。后续 ART-002 要据此生成、拆层与绑骨，直接照现有文档还需重新决定这些接口。请在玩家提示词中补一份可执行清单（文件名、画面内容、挂接骨骼、遮挡/补画、关节重叠；可以引用 T6 的 15% 规则），并补充专项测试检查清单及关键部件的覆盖。无需改已定稿风格或在本卡实际生成部件。

## 已确认

- 实现到交付只变更 `delivery.md` 与 `task.md` 首部状态，没有实现漂移。
- 用户原话“风格定稿。”及迭代记录已收录；不重新讨论用户已定的造型。色板与 DuskStyle、胶囊尺寸与玩家场景、Facing/Art 与 SYS-010、音频格式和事件与 SYS-011/T6 相符。
- `.gitignore` 的 `/assets_src/` 与用户许可、收件箱决定一致；ENV-008 只需核对。两份 Words 设定与主目录未跟踪原件逐字节相同，作为用户提供的风格依据可接受；保留主目录原件，未删除、覆盖或暂存。
- 三张样张与九组提示词均位于允许的任务目录；为定稿提供参考，范围扩展可接受。新增 `tests/test_art_spec.py` 属于根目录要求的相关测试。
- CREDITS 七列、授权白名单、NC/ND 禁令、CC-BY 署名、AI 工具/套餐/提示词、扩展名及排除项均与本次交接一致。不改列名或规则。空表由 ENV-008 补齐现有字体和 SVG，属于明确的任务分工。
- PNG 三项设置与本次交接一致；现有 ENV-008 卡要求检查其中两项，本审查不擅自修改任务卡。

## 独立验证

- 在独立 codex 工作区 detached 固定交付 SHA 后建立审查分支。干净工作区执行 `python codexandclaude/tools/run_checks.py focused --python-all`：G3 `tests` 128/128、`codexandclaude/tests` 67/67，退出 0、无跳过，`content_stable=True`。包含 ART-001 专项 16 项。
- 原始证据：`codexandclaude/runs/20261027T083001.500206Z/summary.json` 与同目录 `evidence.md`，不入库。工具：Python 3.12.14、openpyxl 3.1.5、Node v24.22.1、Git 2.56.0.windows.2。完整命令、时间和哈希附后。
- 独立变异：色板墨色整体改为 `#2b2421`、受击胶囊 96 改为 88、删除授权禁令标记；每轮运行完整 16 项专项，各 1 项失败，全部拦下，随后逐字节恢复。结果：`codexandclaude/runs/art001-review-mutations.json`。仅改正文首处墨色说明的探针未失败，因色板表仍正确，不冒称已拦下；上述色板变异实际修改所有同值出现处。
- 首次启动误在旧 PLN-003 SHA 上运行的 G3 不作为本次证据。交付 SHA 上首次受限运行因 Git LFS 无法写临时元数据而在环境读取阶段退出 128，未执行测试；获得执行权限后上述重跑全部通过，属于环境故障。
- 本次按任务卡复跑 G3；没有独立重跑 G2，不将实现者的 99/99 冒称审查者复跑结果。样张脚本在非游戏运行路径，已有实现者完整 G2 记录；三张样张存在且为 LFS 图像，总览已目检。

## 非阻断建议及交接

- 专项测试大量依赖精确文字，后续宜将尺寸、必需部件与登记规则按结构验证，减少纯措辞调整造成的失败。
- `delivery.md` 把晶弦切割工具列给 ART-002，但当前 ART-002 卡明确将武器素材排除；后续立项或修订任务卡时由用户确认归属，不据交付备注直接扩大 ART-002。
- 登记接口已经明确，ENV-008 可按当前 CREDITS 规则开展；本审查未实现 ENV-008、未合并 master。请 Claude 快进到本审查提交后补齐上述一项，再交复审。

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`e2978c27f4abfbc12a183468aabb89096ef1e508`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-27T08:30:01.500764+00:00；结束：2026-10-27T08:30:17.714469+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际128 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`4a8c65898ce36ee29adb44618c7db9f85ef8c72c`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`253417156a40990c0afa4b0c21d9e87fe1de20a16751ca399e7266a80da38a4f`；工作区范围指纹（原始字节）：`e97dab21f4ffde487801e3fc86740fb5a77f80fe2c4b640a864f4eea529d3e81`。
全工作区指纹：`0e3ce59cde49dcb9dd59ed251a50e34ae7ee5fa998e2538b0ed777bd049b19eb`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261027T083001.500206Z\001.txt`；SHA256=`f9b455b23918e55309ab957ccd0f1c7c14e1ad8984f5953a631557e12fb71b3e`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.234秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261027T083001.500206Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.265秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261027T083001.500206Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261027T083001.500206Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261027T083001.500206Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.156秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261027T083001.500206Z\006.txt`；SHA256=`56d479f50e2104b1492eb8ac25d6be8f43dabad99f76f91cdabec54ec7a16970`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.235秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261027T083001.500206Z\007.txt`；SHA256=`9b40ddba3161fe064790b5c06e2df80565d3edffe4ddcd544099a447c4242ec0`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

