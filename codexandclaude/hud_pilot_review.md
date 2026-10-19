# HUD-001：Codex 独立审查记录

审查日期：2026-10-19。修复提交：3d07d7308d461efc74cc5a2f722332118766ead9。工作区：D:\31days\codexandclaude\worktrees\codex-review，分支 codex/hud-layout-review。未合并 master。

## 审查结论

未发现阻止本次局部修复的代码问题。六个修复交付文件与任务授权清单一致；UI 公开方法和信号保持，存档失败提示的清空统一经过 save_failed("")。本轮不涉及玩法、存档算法、输入配置、结局层级或正式 HUD 重设计。

这不是最终合并授权。独立验证和截图复查通过；用户随后反馈其他验收无问题，但 Xbox 手柄在暂停菜单只能移动选择、所有按键均不能确认。该输入问题已获另行授权并修复，完整自动回归通过，等待用户实机复验；暂不合并。

## 自动验证证据

1. 核对 Claude 的完整报告，确认 72 个条目的名称、顺序与当前验证清单完全一致，退出码均为 0；70 个套件各有匹配的 failures=0 摘要，无错误、解析失败、泄漏或超时标记。报告 SHA256：798d41af973a4a29117e3d032b61a6b046aaa27b93dea5b939b0cc9e09a97d2a。
2. Codex 独立工作区重新导入，复跑 HUD_LAYOUT_TESTS：65 项、0 失败。
3. 独立工作区运行飞行追击测试以生成本地报告：30 项、0 失败；不是复制旧报告以满足 Python 路径检查。
4. 独立复跑 Python 项目检查 69 项、协作检查 8 项，均通过。

本轮没有再次运行全部 70 个 Godot 套件；完整回归依据是逐项核对 Claude 已完成的报告，另对相关 HUD 和工作区初始化进行独立复跑。修复前的失败和测量依据 Claude 的交付记录；Codex 未独立重放修复前版本。

独立执行日志：codexandclaude/runs/codex_review_validation.txt（被忽略的生成物）。

## 真实渲染截图复查

新增可复现截图工具 codexandclaude/tools/capture_hud_preview.gd，未改游戏源码。它实例化真实主场景，使用唯一测试存档目录，并通过真实 UI 更新与既有 save_failed() 注入错误提示；固定测试状态供截图，结束后删除自己的测试存档，不碰玩家正式存档。

使用 Godot 4.7.2、Compatibility/OpenGL 渲染到实际图像；截图和清理共 31 项检查、0 失败，无引擎错误或泄漏。日志：codexandclaude/runs/hud_preview_validation.txt。

已逐张查看以下六张图（生成目录 codexandclaude/runs/hud-preview/，不提交图像生成物）：

| 文件 | 复查内容 | 结果 |
| --- | --- | --- |
| short_1920.png | 1920×1080，恢复中五行 HUD 与短提示 | 可读，无重叠 |
| short_1280.png | 1280×720，相同状态 | 可读，无重叠 |
| long_1920.png | 1920×1080，长中文提示 | 三行换行，位于 HUD 下方，无右侧溢出 |
| long_1280.png | 1280×720，长中文提示 | 缩放后仍可读，无重叠 |
| pause_1280.png | 调用真实暂停菜单 | 菜单绘制在 HUD/提示上方，布局可读 |
| settings_1280.png | 调用真实设置菜单 | 控件和选项可读 |

截图中的“存档失败”是安全注入的测试提示，不代表磁盘或正式存档发生故障。背景为项目已有灰盒场景。截图只证明这些固定状态下的绘制结果，不代替完整游玩、真实输入、全屏切换或真实磁盘错误处理验收。

复跑截图工具（从独立工作区根目录，在正常图形会话运行）：

```powershell
& 'D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path game --script 'D:\31days\codexandclaude\worktrees\codex-review\codexandclaude\tools\capture_hud_preview.gd' --rendering-method gl_compatibility
```

该工具需真实图形渲染，不能以 --headless 运行；测试状态不是玩家当前进度。

后续增加 --interactive 模式供用户验收，具体步骤见 hud_acceptance.md。交互模式自动冒烟检查（注入暂停动作、进入真实设置并清理测试存档）7 项通过，截图模式复跑通过，69+8 项 Python 检查通过。这些自动动作不冒充用户真实按键或手柄验收。

## 未完成与工作区保护

- 用户反馈文字、窗口、全屏及其余操作无问题；Xbox 手柄暂停菜单确认映射已修复，须由用户再次实机检查。
- 不以截图或自动调用 show_pause()/show_settings() 声称真实按键已验证。
- 主目录原有 T6/T7、project.godot 的未提交修改保留；未复制、提交或合并到试点。
- 本工作区导入造成的两个 .svg.import 元数据状态，无内容差异，协调者只恢复自己运行导入产生的状态；Claude 工作区的相同状态未处理，留给用户决定。
- 暂不合并 master，不推送、不删除分支或工作区。用户完成剩余验收并明确确认后，再核对主目录现有改动、执行集成和必要复测。

## Xbox 确认输入诊断

用户确认：Xbox 手柄，暂停菜单能上下移动，已尝试所有按钮但无法确认选项。

运行时只读检查显示 ui_accept 的绑定仅有 Enter、小键盘 Enter 和 Space；ui_up/ui_down 有手柄方向绑定。因此方向能移动，但 A 没有被当作菜单确认。未修改的 project.godot 也没有提供 ui_accept 覆盖。

工具 codexandclaude/tools/probe_controller_confirm.gd 在暂停状态的真实 Godot Button 上复现：原始 Xbox A 激活次数为 0。仅在该测试进程内给 ui_accept 临时补充 device=-1 的 Xbox A 后，设备编号 0、1、2 均可激活按钮，原键盘绑定保持，结束前恢复映射；7 项检查通过。日志为 codexandclaude/runs/controller_confirm_probe.txt。

诊断后建议正式补充 Xbox A → ui_accept，并保留原键盘确认键；不改变跳跃、攻击等游戏操作。因涉及 game/project.godot 输入配置，曾按协作规范暂停等待确认。用户随后明确同意；后续实施与验证状态见 controller_confirm_fix.md，仍不把失败的手柄验收记为通过。
