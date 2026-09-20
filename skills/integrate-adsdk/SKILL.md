---
name: integrate-adsdk
description: >-
  将宿主 Android 工程通过 adSdk AAR 接入或切换广告聚合（AdMob / MAX / TopOn / TradPlus，
  含多平台并存）。覆盖 enable_platform 打包、替换 AAR、Gradle 依赖与仓库、AdCallback
  凭证、adConfig.json platform、ProGuard、埋点迁徙与平台专属坑。Use for 切换广告聚合、
  接入 adSdk、enable_platform、adSdk AAR、compare_price、maxID、toponAppId、
  tradplusAppId、platform topon/tradplus、Max、TopOn、AdMob、TradPlus。
disable-model-invocation: false
---

# 宿主切换 / 接入广告聚合（adSdk）

把已用 **adSdk** 的 Android 宿主切到目标聚合，或新增/删减平台。广告能力走 `AdCallback` 实现类，不直接调各网络 SDK。

**先定目标平台，再改代码。** 不要默认切到 TradPlus。

支持平台：`admob` / `max` / `topon` / `tradplus`。可单平台，也可逗号并存。

依赖坐标、仓库、ProGuard 见 [reference-deps.md](reference-deps.md)。  
平台专属坑见 [reference-pitfalls.md](reference-pitfalls.md)。  
启动页 / 热启动 / 三个广告标志位见 [reference-host-logic.md](reference-host-logic.md)。

```
任务进度：
- [ ] 已确认：当前平台、目标平台（只接一个 / 多平台并存）、是否删除旧平台
- [ ] 已收集目标平台凭证、广告位、中介清单、Remote Config Key、测试+正式包名、namespace
- [ ] adsdk 已按目标 enable_platform 打出 AAR（TradPlus 时含 compare_price）
- [ ] 宿主 libs 已替换 adSdk-release.aar；按目标平台补齐额外 AAR
- [ ] 已移除不再使用的旧聚合依赖与自定义 Adapter
- [ ] 已按打包脚本打印添加目标平台主包 + 中介 + Maven 仓库
- [ ] AdCallback：目标平台凭证已填；未启用平台返回空串
- [ ] adConfig.json（测试+正式）广告位 platform 规则正确
- [ ] Manifest meta-data 与 namespace 一致
- [ ] ProGuard 已 keep 仍在使用的平台
- [ ] 埋点与启动页/冷热启动逻辑已迁徙，未误删仍在用的平台专用逻辑
- [ ] debug / release 均能初始化且无 ClassNotFoundException
```

## 0. 先收集，再改代码

**信息不齐时不要改依赖、不要换 AAR。不确定就问。**

向运营确认两件事：

1. **目标平台集合**（`enable_platform`）
2. **旧平台是删还是留**（只接新平台才能删旧依赖 / 旧广告位 / 旧专用逻辑）

| 收集项 | 何时必填 | 用途 |
|--------|----------|------|
| **当前平台** | 始终 | 决定删哪些依赖、哪些专用逻辑 |
| **目标平台** | 始终 | `enable_platform` |
| **测试 + 正式 `applicationId`** | 始终 | `package_name` 白名单 |
| **adsdk namespace** | 始终 | 公开 API = `{namespace}open`；Manifest `android:value` |
| **广告位 ID 列表** | 始终 | `adConfig.json` 的 `adInfos[].id`，覆盖开屏/插页/原生等 |
| **中介清单** | 目标含 max/admob/tradplus | 与运营后台一致 |
| **Remote Config Key** | 始终 | `remoteAdConfigKey` |
| **MAX SDK Key** | 目标含 `max` | `maxID` |
| **TopOn App ID + App Key** | 目标含 `topon` | `toponAppId` / `toponAppKey` |
| **TradPlus App ID** | 目标含 `tradplus` | `tradplusAppId` |

凭证非空才算齐。未启用的平台不要向运营要 ID，AdCallback 留空串。

## 1. 按目标平台打包 adSdk AAR

在 **adsdk** 工程执行，不是宿主。常见路径：与宿主同级的 `adsdk/`。

编辑 `project.config`：

```properties
project_code = {代号}
package_name = {测试包名},{正式包名}
namespace = {宿主包名前缀}     # 例 com.ai.smart → API 包 com.ai.smartopen
enable_platform = {目标平台}   # admob / max / topon / tradplus，逗号分隔
max_mediation = {MAX中介}      # 仅 enable 含 max 时有效
admob_mediation = {AdMob中介}  # 仅 enable 含 admob 时有效
```

只打目标平台：不要把已确认不用的平台留在 `enable_platform`。  
多平台并存：把要留的和要加的都写上。

```bash
sh configure_project.sh
```

输入 `0` 开始打包。

| 产物 | 说明 |
|------|------|
| `aar-records/{代号}/` | 归档 AAR + mapping + config |

**硬规则：** 各平台 SDK 在 AAR 内为 `compileOnly`，运行时依赖由宿主提供。漏接宿主依赖 → 初始化即崩。

## 2. 宿主替换 AAR

```
app/libs/
├── adSdk-release.aar              # 覆盖为本次打包产物
└── compare_price-release.aar      # 仅目标含 tradplus：从 adsdk/ad/libs/ 拷入
```

```kotlin
implementation(files("libs/adSdk-release.aar"))
// 仅 tradplus：
implementation(files("libs/compare_price-release.aar"))
```

公开 API 包名必须与 AAR 一致；换 namespace 重打后，宿主 import / Manifest 同步改。类名带打包前缀。

## 3. Gradle：按「删旧 / 加新」改依赖

**优先以 adsdk 打包结束时脚本打印的 `dependencies` / `repositories` 为准。** 形态见 [reference-deps.md](reference-deps.md)。

| 目标含 | 宿主必须加 |
|--------|------------|
| `admob` | AdMob SDK + 已选 `admob_mediation` Adapter |
| `max` | MAX SDK + 已选 `max_mediation` Adapter |
| `topon` | 打包脚本不打印中介；向运营要 TopOn 依赖与仓库 |
| `tradplus` | TradPlus 主包 + `compare_price` + 运营已开启的 Adapter / 仓库 |

**仅当运营确认不再使用该平台时才移除：**

| 删掉的平台 | 同时移除 |
|------------|----------|
| MAX | `com.applovin:applovin-sdk`、`com.applovin.mediation:*` |
| TopOn | `com.thinkup.sdk:*`、宿主 `**/topon/custom/**` |
| AdMob | `play-services-ads` 及 AdMob 中介 Adapter（UMP 仍可能需要 ads） |
| TradPlus | `com.tradplusad:*`、`compare_price-release.aar` |

只加运营后台 **已开启** 的广告源，勿全量抄死版本号。

目标平台的 App ID / SDK Key 写入宿主 `BuildConfig`（或现有配置类），不要写死到业务代码：

```kotlin
// 按实际启用的平台添加，未启用的不要加
buildConfigField("String", "MAX_SDK_KEY", "\"${...}\"")
buildConfigField("String", "TOPON_APP_ID", "\"${...}\"")
buildConfigField("String", "TOPON_APP_KEY", "\"${...}\"")
buildConfigField("String", "TRAD_PLUS_ID", "\"${...}\"")
```

## 4. AdCallback 实现类

公开 API 在 `{namespace}open`。字段以 **当前 AAR** 为准：

```kotlin
override val maxID: String get() = BuildConfig.MAX_SDK_KEY          // 不接 MAX → ""
override val toponAppId: String get() = BuildConfig.TOPON_APP_ID    // 不接 TopOn → ""
override val toponAppKey: String get() = BuildConfig.TOPON_APP_KEY
override val tradplusAppId: String get() = BuildConfig.TRAD_PLUS_ID // 不接 TP → ""
```

- `askAdmobEcpm`：仅 **AdMob + `AdLoadMode.Multi`** 需要；切走 AdMob 可删旧比价 jar。TradPlus 比价走 `compare_price`，不要混用。
- `canForceCloseApplovinAd`：仅目标仍含 MAX 时保留；切走 MAX 可删。
- `canReportAdmobImpression`：仅 AdMob；问运营是否已开 AdMob 自动收集，没开才返回 `true`。
- `getNativeAdStyle`：AdMob 用 `adMobLayoutResId`（根节点必须 `NativeAdView`）；MAX / TopOn / TradPlus 共用 `otherLayoutResId`。参数以当前 AAR API 为准。

Manifest：

```xml
<meta-data
    android:name="{完整类名.AdCallbackImp}"
    android:value="{namespace}" />
```

`android:value` = 打包时 `namespace`。若与广告 SDK 合并冲突，可加 `tools:replace="android:networkSecurityConfig"`。

## 5. 广告配置 JSON

必须同时有 **测试** 与 **正式** 配置（本地 assets + Remote Config 同结构）。

```json
{ "id": "{unit-id}", "value": 50, "format": "nav", "platform": "{admob|max|topon|tradplus}" }
```

| format | 含义 |
|--------|------|
| `open` / `int` / `nav` / `ban` / `video` | 开屏 / 插页 / 原生 / Banner / 激励 |

**platform 推断规则（漏写会填错平台 → 无填充）：**

| 平台 | JSON `platform` | 不写时 |
|------|-----------------|--------|
| AdMob | 可写 `admob` | `id` 以 `ca-app-pub` 开头 → AdMob |
| MAX | 可写 `max` | 非 `ca-app-pub` 且无 platform → **默认 MAX** |
| TopOn | **必须** `topon` | 不会推断 |
| TradPlus | **必须** `tradplus` | 不会推断，也不会回退成 MAX/TopOn |

切走某平台时，删掉或改写该平台的 `adInfos`，避免残留旧 unitId。

## 6. 埋点与广告逻辑

改依赖前，先在宿主里定位 **旧 `AdManager` 标志位、`AppObserver`、启动页**（典型：`com/ai/smart/AppObserver.kt` + Splash）。这些是宿主 UI 状态，**不要跟着旧 AdManager 一起删**。迁徙细则见 [reference-host-logic.md](reference-host-logic.md)。

### 6.1 埋点

原项目埋点上报必须不变，迁到 `AdCallback` 实现类（`adEvent` + 可选 `onAdRequest` / `onAdShow` / `onAdClick` / `onAdPaid`）。字段说明以 **adsdk** `README.markdown` 为准。插页/开屏/原生/Banner 展示成功若原项目是宿主自己报的，保持仍由宿主报。

### 6.2 三个标志位：从旧 AdManager 挪到宿主

旧工程通常在 `AdManager` 上：

```kotlin
var clickFullScreenAd = false   // 全屏广告被点击
var fullAdInShowing = false     // 全屏广告正在展示（用于退后台召回通知）
var clickOpenMaxAd = false      // MAX：在启动页点了 AppLovin 全屏，禁止强制关页
```

切到 adSdk 后，旧 `AdManager` 会消失。把它们放到 **宿主可读写的位置**（`AdCallback` 实现类或 Application），再接到回调：

| 时机 | 动作 |
|------|------|
| `onAdClick`（OPEN / INT / REWARD） | `clickFullScreenAd = true`；`fullAdInShowing = true`；若目标仍含 MAX 且栈里同时有 `AppLovinFullscreenActivity` + 启动页 → `clickOpenMaxAd = true` |
| `onAdClose` / 展示失败 | `fullAdInShowing = false` |
| 启动页 `onResume` | `clickFullScreenAd = false` |
| 展示 MAX 开屏/插页前 | `clickOpenMaxAd = false` |
| `canForceCloseApplovinAd()` | 返回 `!clickOpenMaxAd`（切走 MAX 后可删，默认 `true`） |
| `onAdActivityForceClose` | 把启动页 `adIsInShow` / `isInShowAd` 置 false，避免热启动套娃 |

**`clickFullScreenAd`：** 开屏 `onAdClosed` 后若为 true 则 **不要立刻 `go()`**；插页关闭后若为 true 则先记下待跳转功能（如 `lostFunction`），回来再执行。  
**`fullAdInShowing`：** `AppObserver` `ON_STOP` 时若为 true，发「广告召回」通知，不要改成普通退后台通知。  
**`clickOpenMaxAd`：** 仅 MAX。`ON_STOP` 时若为 true，**禁止** `AppLovinFullscreenActivity.dismiss`，否则会无限热启动。切走 MAX 后删除该标志和对 `AppLovinFullscreenActivity` 的引用。

### 6.3 启动页（冷启动）必须原样保留

只把 `AdManager.xxx` 换成 `AdCallback` 实现类，流程不要改：

1. `onCreate`：`onHotStart()`（清过期缓存、拉 Remote Config、跨天重置计数）→ 进度动画 → `loadAd(开屏及相关位)`
2. 动画期间可再次 `loadAd`；`haveAdCache(OPEN)` 或加速条件满足 → 有开屏走 `goWithAd()`，否则 `go()`
3. `goWithAd()`：`adIsInShow` 防重入；`showOpenOrInt`；`onAdClosed` / `onAdShowFail` 里按 `clickFullScreenAd` 决定是否 `go()`
4. `onResume`：复位 `clickFullScreenAd`；`canAnimResume` 为 true 则重跑进度动画
5. 通知权限等异步：权限回来后再决定 `goWithAd` / `go`

### 6.4 热启动与退后台关广告

宿主 `AppObserver` 继续负责，不要交给「只换 AAR」:

- **`ON_START`：** `canShowHot` 且当前不在启动页/引导页时，再开启动页。栈里已有全屏广告 Activity 时 **不要**再开 Splash（原 MAX 工程判断 `AppLovinFullscreenActivity`；切走 MAX 后改成判断栈内是否仍是广告页，避免套娃）。
- **`ON_STOP`：** `canAnimResume = true`；按 `fullAdInShowing` 发广告召回通知；对非宿主包名的广告 Activity 强制关闭。
- **强制关闭：** MAX 用 `dismiss("app_force_dismiss")` 且受 `clickOpenMaxAd` 约束；Bigo 开屏用反射 `onAdSkipped`（`OutOpenActivity.tpnClose` / adsdk `bingoAdClose`）。adsdk 自带的 `AppObserver` 也会关第三方广告页，宿主通过 `canForceCloseApplovinAd` / `onAdActivityForceClose` 对齐，不要两边互相打架。
- 从通知进 `OutOpenActivity` 时，同样先关广告页再进启动页。

**仍在目标集合中的平台**，其专用逻辑保留（MAX 关页、Bigo skip、`clickOpenMaxAd`）。  
**已确认切走的平台**，删除对应 import 与分支，但 **6.2 / 6.3 / 热启动开 Splash** 这些跨平台流程必须留下。

## 7. ProGuard + 坑

正式包按 **仍启用的平台** keep，规则见 [reference-deps.md](reference-deps.md) 与 [reference-pitfalls.md](reference-pitfalls.md)。

常见必做：

- 含 TradPlus → keep `com.tradplus.**` + `com.tp.compareprice.**`，且必须接入 `compare_price`
- 含 MAX → keep `com.applovin.**`
- 含 TopOn → keep `com.thinkup.**`
- 换包名 → `package_name` 已含正式包并 **重打 AAR**

## 8. 验收

| 场景 | 期望 |
|------|------|
| debug / release 冷启 | 不崩（TradPlus 尤其检查 compare_price） |
| 开屏 / 插页 | 目标平台有填充与展示 |
| 首页原生轮播 | 连续可展示；TradPlus 无隔次空壳 |
| 旧平台已删除时 | 无旧 SDK 类引用、无旧 unit 请求 |
| 多平台并存时 | 各 platform 的 unit 都能走到对应 SDK |
| 换包名 | 白名单已含并重打 AAR |
| 启动页冷/热启动 | 进度条、开屏展示/关闭跳转与切前一致 |
| 启动页点击全屏广告 | 不立刻 `go()`，回来后不热启动套娃 |
| 展示中退后台 | 走广告召回通知；MAX 点击开屏时不强制 dismiss |

## 9. Agent 约束

1. 先确认目标平台，不要默认 TradPlus。  
2. 不要只换 AAR 不改依赖。  
3. 目标含 TradPlus 时不要漏 `compare_price`；不含时不要强行接入。  
4. 不要省略仍启用平台的正式包 keep。  
5. TopOn / TradPlus 的 `adConfig` 不要省略对应 `"platform"`。  
6. 不要漏把正式包名写入 `package_name`。  
7. 中介版本以运营与 **打包脚本打印**为准，不要抄过期坐标。  
8. 改 adsdk 后必须 clean 重打 AAR，确认仍有 `{namespace}open`。  
9. 信息不全先问；不要改无关宿主路径或写死某个业务工程的 `AppConfig`。  
10. 不要删除仍在使用的平台专用逻辑与埋点。  
11. 不要把 `clickFullScreenAd` / `fullAdInShowing` / 启动页热启动随旧 `AdManager` 删掉；MAX 未切走时也不要删 `clickOpenMaxAd`。
