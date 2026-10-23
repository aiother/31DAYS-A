# SYS-010 交付记录

实现：Codex｜审查：Claude｜级别：L｜分支：`codex/SYS-010`
基线：`519a7f66814b26ef3309184c3c1aa0f7d9bfc6a7`（第八批已批准任务卡合入后的 master）。
实现 SHA：`bc03e8aefb852584da2f1ea7a5ced6240b162b4d`。
状态：实现与自检完成，待 Claude 审查；用户 G4 尚未进行。未合入 master。

## 范围与结果

- `CharacterAnimationState` 投影玩家与三类普通敌人的现有状态；玩家和无色基础脚本各仅新增一个查询，单色 / 天人继承后按真实类型细分。现有逻辑分支、数值、AI、判定时机、输入映射、存档、旧断言均未改。
- `CharacterAnimator` 挂在玩家 / 无色基础场景的 VisualRoot 下，继承场景自动得到组件。手动 AnimationPlayer 只读真实阶段进度；暂停时显式冻结。起跳、普通落地、复活的短演出窗只在观察器内，不影响玩法时钟。
- 集中映射 `placeholder_map.tres` 以轻微缩放表示状态；详细键优先、通用名次之，缺资源 / 无效视觉轨道回退占位。只允许视觉子树的显示属性，拒绝绝对路径、越界路径和方法 / 音频回调。
- 原视觉脚本零改动。旧 Sprite 的受击变色、无敌闪烁、奖励光环与落地反馈仍走原路径。新资源不缩放物理角色或碰撞。保底实体继承无色基础组件；生成和奖励行为未改。
- 新增 `game/docs/character_animation.md`：完整状态键、朝向与进度、资源替换、骨骼 / 关键逐帧混用、视觉轨道安全边界及命名。正式 Art 子树、正式素材、Boss / 10 / 幸存者和特效均留给后续任务。
- 新套件及验收脚本的 `.uid` 一并入库，套件首行登记；没有修改流水线或计数常量。

## 测试

先在基线写四场景查询测试，得到 `CHARACTER_ANIMATION_TESTS checks=4 failures=4`（查询尚不存在），再实现。最终新套件 **77/0**；无存档验收入口自检 **4/0**。

新套件使用真实移动实验室、真实玩家输入、真实物理帧：待机 / 步行 / 跑步 / 转身、完整跳跃顺序、重落地；三个方向 × 两段连击的前摇 / 判定 / 后摇；正常与贫乏闪避；恢复循环、松键 / 受击中断；受击、倒地、消散、死亡和复活。三类敌人以真实 AI、伤害和动作入口验证待机 / 追击 / 攻击 / STUN / 死亡，单色轻重击和两种 Motion，天人连击与重击 / 远程 / 反击、三种 Motion。天人的重击与远程个别用例调用现有真实动作入口，然后由物理帧推进，不直接赋值动画状态枚举。

资源检查实际加载独立 `idle_override.tres`，证明只替换待机，行走仍用原资源，视觉确实变化、碰撞不变；缺路径和危险轨道回退。100 次立即查询前后核对玩法字段不变；暂停同时核对玩法字段、动画时钟与 AnimationPlayer 定位。

G1 中的玩家 / 战斗 / 三类敌人 / 战役套件全部包含于本次 full，原断言零改动，相关套件全部通过；Boss 套件亦通过。没有以新增动画查询断言替代旧玩法检查。

| 单点变异（每项运行后按原字节还原） | 新套件结果 |
| --- | --- |
| 贫乏闪避一律报告普通 dodge | 77 项中 1 项失败，退出 1 |
| 顶点窗口改为只接受几乎精确零速度 | 77 项中 1 项失败，退出 1 |
| 移除动画驱动的暂停门禁 | 77 项中 1 项失败，退出 1 |
| 查询中偷偷扣 1 点可能性 | 77 项中 2 项失败，退出 1 |

四项均无 SCRIPT ERROR，都是断言检出。原始日志在 `codexandclaude/runs/sys010-mutation-*.txt`，汇总 `sys010-mutations.json` 的 SHA256：`20f14203236c6d525881fe8be6219a5825764efb446347d54684db53076eb639`。

G1 命令：

```powershell
Godot --headless --path game --fixed-fps 60 --script res://tests/test_character_animation.gd
Godot --headless --path game --fixed-fps 60 --script res://tests/acceptance/sys010_animation.gd -- --self-test
```

原始 G1 日志 `codexandclaude/runs/sys010-g1.txt`，SHA256 `2b4e8212535a79a2fafe0b7cdd3c69dcdc979e4bf969fcd4af7657a5060abc64`；验收自检日志 `sys010-acceptance.txt`，SHA256 `1a6428379dac42b5815fba63fa5dddce6803ae76365776f858b7e3a25d071505`。

**完整检查**：`python codexandclaude/tools/run_checks.py full --jobs 4`，G2 **95/95**（导入 + 主场景 180 帧 + 93 套件），G3 **108/108 + 67/67**，`content_stable=True`。引擎 ERROR / WARNING / ObjectDB 泄漏均 0。完整运行在实现提交前进行，摘要的 SHA 是基线加未提交实现，`dirty=True`；被测差异及新文件哈希见下方自动摘要，之后原样提交实现。**不将本次脏来源当作可复用来源**；Claude 须按固定交付 SHA 独立检查。

过程中的检查问题：静态资源检查把新测试中故意缺失的路径及动态目录前缀当成真实文件引用。仅调整测试字符串的构造，保留原结构检查与缺资源断言；G3 随后通过。修正前的一次 full 被主动中止，不作为证据；最终证据为下方完整运行。

## 用户 G4（可选入口已交付，待进行）

```powershell
Godot --path game --script res://tests/acceptance/sys010_animation.gd
```

入口复用无存档移动实验室，没有 SlotStore 或会话，不接触玩家存档；自定义 SceneTree 由现有设置服务自动使用临时设置目录。关闭窗口即可结束，不新增 project.godot 按键。

开局生命 1、可能性 10，原键位操作移动 / 跳跃 / 三方向攻击 / 闪避 / 长按恢复。F1 / F2 / F3 在玩家附近替换一只无色 / 单色 / 天人；F4 尝试受击、F5 尝试致死、F6 复活并补足资源、F8 暂停，仅验收进程内有效；伤害仍受原无敌 / 保护时间限制。面板只读显示动画查询。

用户检查：动作和显示的状态同步；跳跃各阶段与平台重落地可观察；正常 / 贫乏闪避的姿态不同、恢复中断后退出循环；受击 / 无敌 / 奖励的旧反馈保留；暂停时角色和动画均冻结，恢复后继续。正式美术质量不属于本任务。

## 需要审查者留意

1. 为没有现成计时的起跳 / 普通落地 / 复活设置了动画侧短演出窗；它们没有写回玩家或新增玩法锁定。顶点是采样窗口，不是改变重力。
2. 占位只做 VisualRoot 的微小缩放。有限阶段按真实进度 seek；无有限进度的状态按真实 delta 播放。换状态还原上段跟踪的视觉属性，不触碰现有 Sprite 反馈属性。
3. 轨道安全校验限制节点、类型和属性，正式美术资源的键值数值类型仍需资源接入任务验证；不允许动画回调反向改变玩法。文档说明了重新加载资源的约定。
4. 本任务新增可选的无存档实验室，没有复用需要存档会话的通用夹具；自检只证明可启动。用户 G4 结果尚未取得，不声称通过。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`519a7f66814b26ef3309184c3c1aa0f7d9bfc6a7`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**非干净运行（或状态未知），不能作为复用来源**。
开始：2026-10-23T09:13:24.735082+00:00；结束：2026-10-23T09:24:22.948126+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际95 / 预期95；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`bf3ef533e2a2c22499cf10ef4b0ba6ccd6c8d145`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`72e0841c68fda48d213af313fe394aa428fb36251226f721cae717272f081e62`；工作区范围指纹（原始字节）：`791d42594d0a1c658dfcdda32c971da6669a0d9fa8f57255a17082de1c358a7a`。
全工作区指纹：`a21d6942d7bf39bdf42e6f87a7661715ddf534a476e7fdb4cc24be1a8b1f597a`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e76873b0af16d39a353b03b677f9e82492e4dbad7b6e304f26f72f12241b5fe5`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e76873b0af16d39a353b03b677f9e82492e4dbad7b6e304f26f72f12241b5fe5`。
- 未跟踪 `game/animation/character_animation_map.gd` SHA256：`e459d8af4277bdc4138afff05c75749f9b4a1e5e8f64eb50863b5fcfcfa0438d`。
- 未跟踪 `game/animation/character_animation_map.gd.uid` SHA256：`2d053f722f8742729bdec8663e4758086179a0e76ea676f390fa59ac8d76d2ac`。
- 未跟踪 `game/animation/character_animation_state.gd` SHA256：`06e376d4069718680fd9b0047ceaf69bbbe8e7245b652d477c18b05db0a000a2`。
- 未跟踪 `game/animation/character_animation_state.gd.uid` SHA256：`baed2a0c91532437f72003ae136e0a244e35706842f0c02d831a39d155c4a7d2`。
- 未跟踪 `game/animation/character_animator.gd` SHA256：`b30634a0bd2b24c534d6510205810284512e91b28934c1eb0e84f584b3c7a5bb`。
- 未跟踪 `game/animation/character_animator.gd.uid` SHA256：`f558ee014c04cf0e6285bc58493bbf411720bced9e85f0049e1a652e9097b4af`。
- 未跟踪 `game/animation/placeholder_map.tres` SHA256：`ac252975b2f287d947e18af98d38d757417c761cdb497e67f55bb51bdbca0850`。
- 未跟踪 `game/animation/tests/idle_override.tres` SHA256：`b09b0a0dc023084837cba5789ea4af99657b203a9b8106df2732a8daed2f88dd`。
- 未跟踪 `game/docs/character_animation.md` SHA256：`794a11d6525a2fa9078b8093f8552cdea17dd0566192a4849595284bec069900`。
- 未跟踪 `game/tests/acceptance/sys010_animation.gd` SHA256：`a38104fb3641cd848c63510e86d84b35e03c26b627fd1bbe93f4c0a75744c06d`。
- 未跟踪 `game/tests/acceptance/sys010_animation.gd.uid` SHA256：`abb5f18aef92521a9c52e4d7453912a25c0e73c7f18a05b31fc2ff75a079c2d3`。
- 未跟踪 `game/tests/test_character_animation.gd` SHA256：`75fc414015522a6b26b671bbfbfabc51d99c746aee58168d29b8e5a827d8764d`。
- 未跟踪 `game/tests/test_character_animation.gd.uid` SHA256：`30c85aad7867c28fda6b2ed8c9ae6262298e3925aad57c9016aa7a7f1bfb003c`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T091324.734554Z\001.txt`；SHA256=`a813ccf89843963ade88f68f9f5c9a7d0a1ba09c04b35e8ffdd97d58e847f6ae`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T091324.734554Z\002.txt`；SHA256=`1d3d29ae36a8544da848b61f0d80d066f9beb54a8c97b067c4b1a9dd769c7bde`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T091324.734554Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.265秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T091324.734554Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T091324.734554Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T091324.734554Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261023T091324.734554Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=642.906秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T091324.734554Z\007.txt`；SHA256=`1c47182e2f74d1d3b34f1f375206fda303a6eb72adcb625207ba2be6a88c11ac`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.172秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T091324.734554Z\008.txt`；SHA256=`d1b59b69be1662a59a4b8c1ae9d8ce023e0fba94fda5a49b08dd760ad8f8fd03`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.687秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T091324.734554Z\009.txt`；SHA256=`e97858c75301985afc4fe1b2e675ff746832239f19628cf90465b9c0711e115e`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T091324.734554Z\engine.txt` SHA256=`cc45d2269f7e03cad18b63c36bf3bc4d785dd3c92a4aa2224f07a65f0c3074c4`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

交付记录与任务卡首部写入后另跑 G3：108/108 + 67/67 全部通过；摘要 codexandclaude/runs/20261023T092713.260671Z/summary.json。
