# 玩家腿部动作骨架示意 v1

- 文件：`player_leg_rig_v1.png`；日期：2026-10-29。
- 来源：内置 image_gen，AI 生成；原始 PNG 直接复制，无裁切、改色或重绘。
- 参考：`player_run_sheet_v2.png`；遵循 `game/docs/art_style.md` 的墨线、纸色、黄昏暖光及 2.5 头身方向。
- 用途：玩家朝右奔跑六关键姿势的腿部绑定与动作设计参考，非运行时骨骼资源，未接入游戏。
- 图例：近腿（角色右腿）深蓝实线，远腿（角色左腿）紫色虚线；金色圆点为关节枢轴。链条为髋 → 膝 → 踝 → 脚掌。
- 顺序：01 近腿接触 → 02 近腿承重 → 03 远腿前摆腾空 → 04 远腿接触 → 05 远腿承重 → 06 近腿前摆腾空 → 01。
- 目视检查：六姿势及近远腿交换可读；02/05 支撑脚着地，03/06 双脚离地；半透明外形便于观察披风下方的腿。图中髋关节横向错开用于区分两条腿。
- 绑定约束：骨长固定，支撑脚贴地；最终在统一绑定中校准髋位、骨长、2.5 头身与脚底基线。生成图不是可量测的骨骼坐标表，不应逐帧按图缩放骨长。
- 验证：新增图像解码、尺寸、画面非空和交付说明检查；运行 `python -m unittest discover -s tests`。自动检查不证明运动连续性或脚底无滑动；六帧循环与 06→01 接续需实际绑定播放验收。

## 最终提示词

```text
Create a polished animation rig reference sheet for the current game 《末日前31天》, titled “腿部动作 · 骨架示意”. Use attached six-frame running image as character identity/style reference only. Landscape large high resolution cream paper #efe4cc sheet, dark sepia ink #2b2420, subtle paper texture, clean highly legible Chinese labels. This is an animator's schematic, NOT anatomical skeleton bones. Focus on joint-and-stick lower body skeletons. Consistent short rounded legs of a 2.5-head-tall chibi, never adult long legs.
Layout: top title and subtitle “玩家 / 朝右 / 奔跑六关键姿势”. Small upper-left standing hooded character matching silver cape/navy clothing/rose gold hem reference, facing RIGHT, with cape drawn translucent to reveal pelvis and short legs. Next to it a large clear single leg joint chain with labeled circles: “髋”, “膝”, “踝”, “脚掌”; upper and lower leg and foot connected. Legend navy solid = “近腿（右）”; muted purple dashed = “远腿（左）”. Gold circles denote joint pivots. Use no teal and no red.
Main middle and bottom section is a wide SIX COLUMN sequence with equal scale skeletal lower bodies, large enough to read. Small pale ghost head and torso outlines above pelvis establish same big-head short-body proportions; no clothing obscuring joints. Every pose has exactly two complete articulated chains hip → knee → ankle → toe, distinct navy solid near leg and purple dashed far leg, clear circular hip knee ankle pivots. Feet have toe direction toward RIGHT; knees bend naturally. Each has same faint horizontal ground baseline, modest vertical pelvis bob, never changes bone lengths. Sequence:
01 “近腿接触”: navy near leg forward to right touching ground heel, purple far leg trailing to left.
02 “近腿承重”: navy foot flat below pelvis on ground with flexed knee, purple heel lifted behind to left; pelvis lowest.
03 “远腿前摆”: purple far knee leading forward to right, navy near leg trailing left; BOTH feet above ground, pelvis high.
04 “远腿接触”: purple far leg forward right touching ground heel, navy near leg trailing left.
05 “远腿承重”: purple foot flat below pelvis with flexed knee, navy heel lifted behind left; pelvis lowest.
06 “近腿前摆”: navy near knee leading forward right, purple far leg trailing left; BOTH feet above ground, pelvis high.
Mark grounded feet with small gold contact patches; mark 03 and 06 “腾空”. Show a thin curved sequence arrow ending “循环至 01”. Bottom notes exactly: “近远腿交替 · 骨长固定 · 支撑脚贴地 · 腾空双脚离地” and smaller “动作设计参考，非运行时骨骼资源”. Plenty of whitespace, strong hierarchy, restrained beautiful hand-drawn technical diagram. No extra legs, no backwards knees, no flesh anatomy, no weapon, no perspective, no elaborate cape blocking the skeleton, no adult proportions. The key deliverable is the readable leg skeleton, not another clothed sprite sheet.
```

