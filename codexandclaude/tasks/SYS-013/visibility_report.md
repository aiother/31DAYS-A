# SYS-013 竖向视野与 Boss 预兆核对

基线：master@cc42d35 加 SYS-013 镜头实现。Godot 4.7.2 实际渲染，1920×1080；普通 ×1.875（视野 1024×576 世界单位），战斗 ×1.5（1280×720）。

**结论：保留普通构图后，从高平台回看下方存在视野盲区；默认战斗倍率也不能同时涵盖宽 1600 世界单位的双方位置。以下只报告，不改关卡。**

## 采样方法与边界

使用生产房间场景、碰撞平台上表面及真实 GameplayCamera，禁用玩法/物理推进后将玩家放在入口和每个水平矩形平台中心；记录镜头实际 view rect，并按平台中心 y 是否在其上/下方列出盲区。平台中心不在垂直范围即记为盲区，不表示整个平台不可见，也不表示该平台是下一跳目标；水平方向越界不计入本表。包含根节点及嵌套平台，排除竖墙/窄门柱；动态召唤平台、落石与飞行路径不在静态样本里。所有样本及完整平台坐标见 `captures/audit.json`；截图哈希见 `captures/manifest.json`。

这份报告证明这些静态位置的构图问题，不证明玩家能按某个输入序列到达所有位置，不替代完整通关或用户 G4。Boss far 是房间两端的构图压力样本，不断言真实 AI 在同一前摇阶段一定能达到该状态。

## 竖向 Room

| Room | 样本数 / 有上下盲区 | 入口上方超界示例（平台中心） | 高处向下超界示例（平台中心） | 截图 |
| --- | --- | --- | --- | --- |
| HD_10002_2 | 7 / 7 | 玩家 (128.0, 1536.0) → Platforms/Step3 (1072.0, 896.0) | 玩家 (1632.0, 640.0) → Platforms/Step4 (1296.0, 736.0) | [entry](captures/HD_10002_2_0.png)、[Platforms/UpperLanding](captures/HD_10002_2_6.png) |
| HD_10002_3 | 9 / 9 | 玩家 (128.0, 1536.0) → Platforms/TurnLanding (1072.0, 896.0) | 玩家 (2336.0, 520.0) → Platforms/Step5 (2000.0, 600.0) | [entry](captures/HD_10002_3_0.png)、[Platforms/ExitLanding](captures/HD_10002_3_8.png) |
| HD_10004_1 | 2 / 0 | 无（已采样水平平台） | 无（已采样水平平台） | [entry](captures/HD_10004_1_0.png)、[ExitLanding](captures/HD_10004_1_1.png) |
| HD_20001_1 | 5 / 3 | 无（已采样水平平台） | 玩家 (1872.0, 848.0) → Platforms/Step1 (1648.0, 992.0) | [entry](captures/HD_20001_1_0.png)、[Platforms/Step2](captures/HD_20001_1_3.png) |
| HD_20001_2 | 4 / 2 | 无（已采样水平平台） | 玩家 (1088.0, 720.0) → Step1 (800.0, 848.0) | [entry](captures/HD_20001_2_0.png)、[RescueLanding](captures/HD_20001_2_3.png) |
| HD_20001_3 | 4 / 2 | 无（已采样水平平台） | 玩家 (1120.0, 880.0) → Step1 (800.0, 992.0) | [entry](captures/HD_20001_3_0.png)、[RescueLanding](captures/HD_20001_3_3.png) |
| HD_20002_1 | 5 / 3 | 无（已采样水平平台） | 玩家 (1872.0, 848.0) → Platforms/Step1 (1648.0, 992.0) | [entry](captures/HD_20002_1_0.png)、[Platforms/Step2](captures/HD_20002_1_3.png) |
| HD_20002_2 | 3 / 1 | 无（已采样水平平台） | 玩家 (1024.0, 992.0) → Platforms/Step0 (768.0, 1136.0) | [entry](captures/HD_20002_2_0.png)、[Platforms/Step1](captures/HD_20002_2_2.png) |
| HD_20003_1 | 5 / 3 | 无（已采样水平平台） | 玩家 (1408.0, 1056.0) → Step1 (832.0, 1200.0) | [entry](captures/HD_20003_1_0.png)、[ExitLanding](captures/HD_20003_1_1.png) |
| NSZC_10001_1 | 7 / 6 | 玩家 (224.0, 1280.0) → Platforms/ChallengeRoof (2480.0, 720.0) | 玩家 (2480.0, 720.0) → Platforms/Step2 (1872.0, 848.0) | [entry](captures/NSZC_10001_1_0.png)、[Platforms/ChallengeRoof](captures/NSZC_10001_1_6.png) |
| NSZC_10002_1 | 8 / 8 | 玩家 (224.0, 1792.0) → Platforms/Step3 (1120.0, 1168.0) | 玩家 (1568.0, 848.0) → Platforms/Step4 (1344.0, 1008.0) | [entry](captures/NSZC_10002_1_0.png)、[Platforms/Step5](captures/NSZC_10002_1_6.png) |
| NSZC_10002_2 | 10 / 10 | 玩家 (224.0, 2048.0) → Platforms/Step2 (448.0, 1520.0) | 玩家 (672.0, 944.0) → Platforms/Step4 (448.0, 1136.0) | [entry](captures/NSZC_10002_2_0.png)、[Platforms/Step5](captures/NSZC_10002_2_6.png) |

普通构图脚底到屏幕底部仅 69.12 世界单位（1080×0.12/1.875），塔楼/堑壕相邻层高通常超过该距离，因此站在上层中心时，下层落点容易被裁掉。表中列出的是实际采样结果；不新增关卡调整或观察键。

## Boss 出招预兆

| Boss / 样本 | 玩家脚底 | Boss 位置 / 预兆中心 | 实际视野 | 预兆中心可见 | 截图 |
| --- | --- | --- | --- | --- | --- |
| HD_10004_1 / near | (800.0, 1280.0) | (960.0, 920.0) / (960.0, 872.0) | (216.0, 646.4, 1280.0, 720.0) | 是 | [near](captures/HD_10004_1_near.png) |
| HD_10004_1 / far | (160.0, 1280.0) | (1760.0, 920.0) / (1760.0, 872.0) | (80.0, 646.4, 1280.0, 720.0) | 否 | [far](captures/HD_10004_1_far.png) |
| HD_20003_1 / near | (800.0, 1536.0) | (960.0, 1536.0) / (960.0, 1488.0) | (216.0, 902.4, 1280.0, 720.0) | 是 | [near](captures/HD_20003_1_near.png) |
| HD_20003_1 / far | (160.0, 1536.0) | (1760.0, 1536.0) / (1760.0, 1488.0) | (80.0, 902.4, 1280.0, 720.0) | 否 | [far](captures/HD_20003_1_far.png) |

near 样本中两场 Boss 的预兆中心均可见；far 样本中预兆在视野右边之外。渴望俯视的地面落击标记仍可见，Boss 本体/面部读招区域超界。实际已接入的 FX 形状、未来正式美术尺寸和真实 AI 时序需要 G4 继续复核，不能仅凭一个中心点宣称全部预兆完整可见。

## 复现

在仓库工作区用 Godot console 执行：

```powershell
Godot --path game --resolution 1920x1080 --script res://../codexandclaude/tasks/SYS-013/capture_audit.gd
```

脚本只挂载房间并渲染，用隔离的缓存目录作兜底，不调用 start_slot/change_room、不推进存档；自动退出并清理自己的临时目录。它不会生成动画帧或改变关卡。
