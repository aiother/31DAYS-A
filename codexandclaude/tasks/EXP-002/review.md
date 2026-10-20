# EXP-002 审查记录

日期：2026-10-20｜审查：Codex｜实现：Claude｜结论：**需修改**

- 固定交付SHA：`42ec8526365616d8eedfcb9530f70b35272eac57`，在Codex工作区用`git switch --detach`检出后审查。
- 实现SHA：`bb5be39730faab84e6e61218f5cbbad475bf62f9`；审查分支：codex/EXP-002-review，从交付SHA新建。
- master已快进到规划SHA `43e7dc2a5c8f9376b9b28db9053ebfddd6ed9c46`，它已是本交付的祖先。任务记录中“合入后再合并master”的描述可在下一次交付更新，无须制造空合并。

## 范围与批准依据

1. 实现到交付只新增delivery.md、修改task.md首部状态。排除EXP-002原型目录、协作测试及本任务目录后的基线到实现差异为空；EXP-001、正式游戏、project.godot、输入映射、存档及验证器均没有改动。
2. 以本轮用户消息提供的原话为批准依据：用户喜欢甲、丙并提出甲为基底加丙的质感与设计，同意“黄昏随末日临近渐入”，并允许“后面一起吧”。任务卡只调整样张方向、完成标准1和3，改为两种混合比例和逐日变化；仍保持既定布局与交互、仍在原型范围内。调整与批准一致，没有扩大为正式美术、正式界面或玩法规则。
3. style.gd固定生命/可能性/成长/透支/警示等语义色，逐日变化作用于氛围、光晕与底色。代码核对及14张已提交截图支持目前实现符合这项设计；但现有冒烟没有关键色不变的断言（见R2）。纸墨/黄昏两种比例及与T7的新增表现、字体尚待选择，README均有说明。
4. 已查看两个样张全部14张截图：徽记、地平线、透支与最后1点生命、暂停时钟、设置盖住时钟、对话框均可辨认。是否选某种比例、黄昏幅度或引入字体由用户G4决定。

## 阻断项

### R1（P2）：缺少“开战余时不足15分钟”的可操作入口

位置：game/prototypes/EXP-002/preview.gd的jump/press（尤其第88～95、109～135行）；任务卡“每个样张必须覆盖的画面”第2项。

`KEY_8 -> jump(4)`始终调用`state.start_final(25.0 * 60.0)`，完全覆盖用户此前调出的第3日余时。按键表没有另一条短余时入口，EXP-001原有P入口也未保留。HUD虽有`final_from <= FINAL_SECONDS`时显示“余时不足”的分支，但正常预览无法进入，因此不能在两个样张下挑选A-016短预算的警示表现。

独立探针向真实Viewport注入按键事件：按8得到final_from=1500、budget=900，按P仍为1500/900。用绘制文本探针核对：该状态只显示普通“最终战倒计时/15:00”；仅直接调用状态的`start_final(552.0)`才得到“最终战倒计时 · 余时不足/09:12”及朱红色。说明绘制分支存在，缺的是用户可达入口。

请在原型中提供明确的长/短预算切换入口并补说明；两个样张都应能通过入口直接显示真实短预算且没有长余时加速演出。回归测试应通过同一个输入入口验证这两种状态及实际显示文字/警示色，不能只在测试里直接改状态而绕开入口。

证据：忽略目录runs/exp002-review-probe.gd、exp002-review-probe.txt。探针继承HUD、记录其ink_text实际调用，未改被审实现。

### R2（P2）：冒烟没有遍历两个样张的全部画面，也没有拦住关键表现缺失

位置：game/prototypes/EXP-002/tests/smoke_test.gd第32～37行及hud_states/pause_menu/dialog_sample。

两个样张循环只执行dusk_rules和hud_states，暂停与对话框在循环结束后执行一次，此时固定为样张二。关键色不随天数变化没有断言；按钮测试覆盖normal/focus/pressed/disabled，未验证hover。最终战只断言状态为final_active且加速计时存在，没有检查画面输出或短预算分支。这不足以满足完成标准4“全部基调、全部画面与状态”，也与本轮交接所述“关键色不变、按钮各状态”的覆盖不符。

临时变异实测（逐项恢复原始字节）：

| 变异 | 原38项冒烟结果 | 判断 |
| --- | --- | --- |
| `_draw_final()`在final_active时直接return，移除全部最终倒计时绘制 | 38/38，退出0，无错误/警告 | 漏检 |
| 暂停视图`_draw()`在sample==0时直接return，移除样张一暂停画面 | 38/38，退出0，无错误/警告 | 漏检 |
| 可能性实际填充色随style.dusk(state)混向生命红色 | 38/38，退出0，无错误/警告 | 漏检关键色变化 |
| 将三个DAY_RANGE都改为0.5～0.5 | 38项中2项失败，退出1，两个逐日递增断言失败 | 正确拦截 |

请将暂停、二级页、对话框和按钮各状态放到每个样张内验证；补足语义色跨日期不变、长短最终预算实际呈现的断言。可用实际绘制消费的表现数据或绘制调用探针，不要求像素截图测试。至少应拦住上表三个漏检变异，并保持逐日变化的现有正向覆盖。不要以只读模拟状态的断言代替新视图是否输出内容的检查。

证据：runs/exp002-review-mutations.json及exp002-mutation-*.txt。变异只临时修改本审查工作区，全部按原字节还原；还原后冒烟与G3均再次通过。

## 非阻断建议

N1：tests/capture.gd以200个process_frame等待最终战演出结束，帧数不等于2.5秒真实时间。现有两张final_countdown截图均停在“时间加速……/22:0x”，未展示演出后的稳定倒计时。建议有上限地等待accelerate_left实际归零，再截图稳定状态；补R1时可另留短预算截图。这能让用户明确区分演出与真实剩余预算。

## 独立检查证据

被测交付SHA为上述42ec852；原型探索按任务卡运行冒烟、G3及引擎前两步，没有运行正式全量76套件。

| 检查 | 命令（在工作区根目录） | 结果 |
| --- | --- | --- |
| 编辑器导入 | Godot --headless --path game --editor --import --quit | 退出0，无ERROR/WARNING |
| 主场景180帧 | Godot --headless --path game --quit-after 180 | 退出0，无ERROR/WARNING |
| EXP-002冒烟及变异还原后复跑 | Godot --headless --path game --script res://prototypes/EXP-002/tests/smoke_test.gd | checks=38 failures=0 |
| EXP-001原有冒烟 | Godot --headless --path game --script res://prototypes/EXP-001/tests/smoke_test.gd | checks=105 failures=0 |
| G3及还原后复跑 | python codexandclaude/tools/run_checks.py focused --python-all | 102/102 + 47/47，complete=true、passed=true |

工具：Godot4.7.2.stable.official.ed1daf0bf；Python3.12.14/openpyxl3.1.5；Git2.56.0.windows.2；Nodev24.19.0。实际Godot为D:/DMyself下控制台版；Python为Codex bundled runtime。

首次G3的dirty=true仅含已知两份SVG.import生成物；确认差异仅换行后恢复，最终复跑20261020T144622.898100Z的SHA仍为交付SHA、dirty=false，两个目录计数完整。原始证据均在忽略的codexandclaude/runs：exp002-review-import.txt、exp002-review-main180.txt、exp002-review-smoke.txt、exp002-review-restored-smoke.txt、exp002-review-exp001-smoke.txt、20261020T144622.898100Z/summary.json及逐命令日志。没有新增正式源码或测试修改；本审查提交只新增review.md。

G4待用户挑选。请Claude先快进到本审查提交，再修订R1、R2，提交新的实现SHA和交付SHA后复审；非阻断N1可一并处理。master仍为规划SHA，未合并本原型。

日志身份：

- exp002-review-import.txt SHA256：`c1f7fc0f916e3d0ee4626c390b506537040ef3b1348072ff7042a4e3ca1731ae`。
- exp002-review-main180.txt SHA256：`83cf0b082206af2aa236c83064fbcfa76be1e00a4aa3558574b2f65965d9481c`。
- exp002-review-smoke.txt SHA256：`eadd40d67dfd20001d97be74e8ed81d753eb81c840c4d314b00e5dc6c5186efb`。
- exp002-review-restored-smoke.txt SHA256：`eadd40d67dfd20001d97be74e8ed81d753eb81c840c4d314b00e5dc6c5186efb`。
- exp002-review-exp001-smoke.txt SHA256：`eb5ee4c71fde9eacf8af6a81913c564c208e61a7580a5b704d28fed38b4d8e68`。
