---
name: complete-pdf-project
description: >-
  以现有 PDF 工程为底板复制出新 PDF 项目：业务与广告逻辑照搬，UI 按 Figma 换肤，
  广告改走 adSdk。路径必须打散；类名/方法名轻度改、保持可读。applicationId 固定
  com.test.app，签名 / google-services / 测试广告 ID 一并复制。Use for 新 PDF 项目、
  完成 PDF 项目、从 Figma 做 PDF、复制 PDF16、换皮 PDF、打散类名路径。
disable-model-invocation: false
---

# 完成一个 PDF 项目

从现有 PDF 工程整份复制底板，**行为照搬**；**路径打散**，类名/方法名轻度差异化并保持可读。UI 按 Figma 换，广告按 [integrate-adsdk](../integrate-adsdk/SKILL.md) 接入。差异化细则见 [reference-diff.md](reference-diff.md)。

```
任务进度：
- [ ] 已确认：项目代号、底板工程、Figma（链接或截图）、目标广告平台
- [ ] 已复制底板到 StudioProjects/{代号}，排除 build / .gradle
- [ ] rootProject.name、APP_NAME、NAME_SPACE 已改；APP_ID / 签名 / google-services / 测试广告 ID 未动
- [ ] 源码路径已打散；类名/方法名与底板有区别但仍可读
- [ ] Figma 与底板页面差异已问过用户
- [ ] UI 已按 Figma 换完，binding id 与点击/广告调用仍在
- [ ] 广告已按 integrate-adsdk 接到目标平台
- [ ] 启动页 / 热启动 / clickFullScreenAd 等标志位仍在
- [ ] debug 能编译安装，主路径可走通
```

## 0. 先问齐，再复制

**底板：** 让用户自己选现有 PDF 工程（`StudioProjects` 下 `pdf*` / `PDF*`）。**用户不选 → 用 `PDF16`。**

还要问（没有就停）：

| 收集项 | 说明 |
|--------|------|
| **项目代号** | 新目录名，如 `PDF21` |
| **Figma** | 文件链接，或导出切图/截图。两种都可以 |
| **目标广告平台** | `admob` / `max` / `topon` / `tradplus`，可多选。走 integrate-adsdk |

**不要问、不要改成正式值（用户上线自己改 `AppConfig`）：**

- `applicationId` 固定 `com.test.app`
- 签名 jks、密码、alias
- `google-services.json`
- AdMob 测试应用 ID：`ca-app-pub-3940256099942544~3347511713`
- MAX 测试 Key：沿用底板 `AppConfig.Key.MAX_ID`

Figma 和底板功能对不上时：**列出差异，问用户**（留着 / 藏入口 / 删），不要擅自砍功能。

## 1. 复制底板

目标：`/Users/tanwei/StudioProjects/{代号}/`

```bash
rsync -a \
  --exclude .git --exclude build --exclude .gradle --exclude .idea \
  /Users/tanwei/StudioProjects/{底板}/ \
  /Users/tanwei/StudioProjects/{代号}/
```

改身份：

- `settings.gradle.kts` → `rootProject.name = "{代号}"`
- `AppConfig.Build.APP_NAME`
- **`AppConfig.Build.NAME_SPACE` 必须换成与底板不同的新 namespace**（公开 API / R 包跟它走）
- 启动图标按 Figma 换

**禁止改：** `APP_ID`（`com.test.app`）、签名、`google-services.json`、测试广告 ID。

复制完立刻做 **§2 差异化**，不要顶着底板的 `com.oowa.pdf` / `view/page/...` 去接 UI。adsdk 的 `namespace` = 新 `NAME_SPACE`，`package_name` = `com.test.app`。

## 2. 差异化（硬约束）

新项目不能是底板目录换皮。**路径必须打散**；类名、方法名只要和底板不完全同一套即可，**必须能读懂职责**，不要改成看不出页面的黑话。细则见 [reference-diff.md](reference-diff.md)。

| 要改 | 怎么改 |
|------|--------|
| 路径 | 新 `NAME_SPACE`；包目录重新切分，不要镜像 `view/page/splash` 这棵树 |
| 类名 | 可轻度改名（`SplashActivity` → `LaunchSplashActivity`），**保留 Splash / Main / File 等可读词**。禁止 `DawnGate`、`NexusBoard` 这种看不懂的名字，也禁止 `MainActivity2` |
| 方法名 | **默认保持可读原名**（`loadAd`、`goWithAd`、`initAnim` 可留）。只需改和底板完全撞车、又几乎无语义的少数名字；不要全量替换 |
| 打散 | 同一底板目录里的类拆到多个新包；layout 文件名可跟着页面改，但仍用 `activity_splash` 这类能看懂的名字 |

**不要改：** `onCreate` / `onResume` 等系统 override、AndroidX/第三方 SDK API、`APP_ID` / 签名 / google-services / 测试广告 ID。

Manifest、`tools:context`、Intent、DataBinding、生命周期观察里的 Activity 判断，跟最终类名走。

## 3. 对照 Figma，只换 UI

页面对照表见 [reference-screens.md](reference-screens.md)。

1. 把 Figma 帧和底板 Activity / Fragment / Popup 列成表。
2. 多出来的、少了的，先问用户。
3. 有 Figma MCP 就拉节点、颜色、标注；没有就用用户给的截图/切图。**没有工具就不要假装能打开 Figma 链接。**
4. 改 `res/layout`、`colors.xml`（`main` 等主题色）、drawable、字体尺寸。
5. **DataBinding id、点击、广告展示、扫描、权限、跳转不要无故删。** 设计要新 id 时，xml 和 Kotlin 一起改。
6. 扫描、Room、文件操作、阅读器、通知、Widget 的**行为**照搬；不要为了 UI 再重写算法。

## 4. 广告改走 adSdk

底板（含 PDF16）仍是宿主 `AdManager`。新项目要接到 adSdk：

1. 完整执行 [integrate-adsdk](../integrate-adsdk/SKILL.md)。
2. 启动页 / 热启动 / `clickFullScreenAd` / `fullAdInShowing` / `clickOpenMaxAd` 按该 skill 的 [reference-host-logic.md](../integrate-adsdk/reference-host-logic.md) 迁到 `AdCallback`，不要删。
3. 测试期凭证：AdMob / MAX 用底板测试 ID；TopOn / TradPlus 没有测试值就问用户，不要编。
4. 正式包名、正式广告 ID **不要现在写进 AppConfig**。

## 5. 验收

- `./gradlew :app:assembleDebug` 通过
- 启动页 → 权限 → 首页 → 打开/生成一份 PDF
- 开屏或插页在测试 ID 下能请求（无填充也要无崩溃）
- 热启动仍进启动页；点全屏广告回来不套娃
- 包路径不是底板那棵 `view/page/...` 树；类名仍能看出启动页/首页/文件列表

## 6. Agent 约束

1. 底板先问用户，不选再用 PDF16。  
2. 行为照搬；**路径打散**，类名/方法名轻度差异化并保持可读，禁止黑话式重命名。  
3. 禁止只改包前缀、目录结构照抄底板。  
4. 不要改 `com.test.app`、签名、google-services、测试广告 ID。  
5. Figma 与功能不一致必须先问。  
6. 广告必须走 integrate-adsdk，不要继续堆一套新的宿主 AdManager。  
7. 信息不够先问。
