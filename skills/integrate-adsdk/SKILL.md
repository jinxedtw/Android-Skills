---
name: integrate-adsdk
description: >-
  将宿主 Android 工程通过 adSdk AAR 接入或切换广告聚合（AdMob / MAX / TopOn / TradPlus，
  含多平台并存）。覆盖 enable_platform 打包、替换 AAR、混淆公开 API、AdCallbackImp
  广告位、AdManager 门面、Gradle 依赖与仓库、adConfig.json platform、原生布局、
  Manifest 合并、ProGuard、埋点与冷热启动。Use for 切换广告聚合、接入 adSdk、
  enable_platform、adSdk AAR、compare_price、tradplusAppId、platform tradplus、
  Max、TopOn、AdMob、TradPlus、加载adapter文件发生错误。
disable-model-invocation: false
---

# 宿主切换 / 接入广告聚合（adSdk）

把已用 **adSdk** 的 Android 宿主切到目标聚合，或新增/删减平台。广告能力走 `AdCallback` 实现类，不直接调各网络 SDK。

**先定目标平台，再改代码。** 不要默认切到 TradPlus。

支持平台：`admob` / `max` / `topon` / `tradplus`。可单平台，也可逗号并存。

依赖坐标、TradPlus adapter 版本规则见 [reference-deps.md](reference-deps.md)。  
平台专属坑见 [reference-pitfalls.md](reference-pitfalls.md)。  
启动页 / 热启动 / 标志位见 [reference-host-logic.md](reference-host-logic.md)。

```
任务进度：
- [ ] 已确认：当前平台、目标平台（只接一个 / 多平台并存）、是否删除旧平台
- [ ] 已收集目标平台凭证、广告位、中介清单、Remote Config Key、测试+正式包名、namespace
- [ ] adsdk 已按目标 enable_platform 打出 AAR（TradPlus 时含 compare_price）
- [ ] 宿主 libs 已替换 adSdk-release.aar；按目标平台补齐额外 AAR
- [ ] 已 javap / 列出 {namespace}open 公开类，后续只用这些类名
- [ ] 已移除不再使用的旧聚合依赖与自定义 Adapter
- [ ] 已按打包脚本打印添加目标平台主包 + 中介 + Maven 仓库
- [ ] TradPlus：adapter 版本后缀与 tradplus 主包一致，且 AAR 内有 GoogleInitManager 等真实类
- [ ] AdCallbackImp：凭证已填；广告位 val 定义在实现类上；未启用平台返回空串
- [ ] 宿主 AdManager 只做门面+标志位，没有重复的 AdPlace enum / NativeType IntDef
- [ ] adConfig.json（测试+正式）广告位 platform 规则正确
- [ ] 原生布局：AdMob 根 NativeAdView；其它平台 otherLayout；控件 ID 一致
- [ ] Manifest meta-data 与 namespace 一致；合并冲突已处理
- [ ] ProGuard 已 keep 仍在使用的平台 + AdCallbackImp + {namespace}open
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
| **Remote Config Key** | 始终 | `getRemoteAdConfigKey()` |
| **MAX SDK Key** | 目标含 `max` | `getMaxID()` |
| **TopOn App ID + App Key** | 目标含 `topon` | `getToponAppId()` / `getToponAppKey()` |
| **TradPlus App ID** | 目标含 `tradplus` | `getTradplusAppId()` |

凭证非空才算齐。未启用的平台不要向运营要 ID，AdCallback 留空串。

## 1. 按目标平台打包 adSdk AAR

在 **adsdk** 工程执行，不是宿主。常见路径：与宿主同级的 `adsdk/`。

编辑 `project.config`：

```properties
project_code = {代号}
package_name = {测试包名},{正式包名}
namespace = {宿主包名前缀}     # 例 com.cell.document → API 包 com.cell.documentopen
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

## 2. 宿主替换 AAR，并识别公开 API

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

公开 API 包名必须与 AAR 一致；换 namespace 重打后，宿主 import / Manifest 同步改。

**每次换 AAR 必须先列出 `{namespace}open` 类名。** 打包会混淆，不要假设叫 `AdCallback` / `AdPlace`。用 `javap` 或 IDE 对照语义：

| 语义 | 典型职责 | pdf06 当前 AAR 示例（会变） |
|------|----------|------------------------------|
| AdCallback | 抽象基类，宿主 `object` 继承 | `NytAdCallback` |
| AdPlace | `label` + `adTypeList` + `bidFromPlaces` | `VgpdqAdPlace` |
| AdFormat | OPEN / INT / NATIVE / BANNER / REWARDED | `VolzjAdFormat` |
| NativeType | BIG / MIDDLE / SMALL | `LbxvkNativeType` |
| NativeAdStyle | 两套 layout + 控件 ID | `TaqrmNativeAdStyle` |
| AdLoadMode | Single / Multi | `SapkAdLoadMode` |
| AdPlatform | 回调里的平台 | `BocgAdPlatform` |
| OnFullAdCallBack | 开屏/插页关闭、失败 | `SldOnFullAdCallBack` |
| OnRewardCallBack | 激励关闭 | `DystgOnRewardCallBack` |
| AdEvent | 埋点 token | `VzjeAdEvent` |

下文用语义名；写代码时用 **当前 AAR 的真实类名**。

## 3. Gradle：按「删旧 / 加新」改依赖

**优先以 adsdk 打包结束时脚本打印的 `dependencies` / `repositories` 为准。** 形态见 [reference-deps.md](reference-deps.md)。

| 目标含 | 宿主必须加 |
|--------|------------|
| `admob` | AdMob SDK + 已选 `admob_mediation` Adapter |
| `max` | MAX SDK + 已选 `max_mediation` Adapter |
| `topon` | 打包脚本不打印中介；向运营要 TopOn 依赖与仓库 |
| `tradplus` | TradPlus 主包 + `adapter-util` + `compare_price` + **版本后缀对齐的** Adapter / 仓库 |

**仅当运营确认不再使用该平台时才移除：**

| 删掉的平台 | 同时移除 |
|------------|----------|
| MAX | `com.applovin:applovin-sdk`、`com.applovin.mediation:*` |
| TopOn | `com.thinkup.sdk:*`、宿主 `**/topon/custom/**` |
| AdMob | `play-services-ads` 及 AdMob 中介 Adapter（UMP 仍可能需要 ads） |
| TradPlus | `com.tradplusad:*`、`compare_price-release.aar` |

只加运营后台 **已开启** 的广告源。TradPlus adapter **禁止**用 `2.66.4.42.1.1.100` 这类空壳版本，详见 [reference-deps.md](reference-deps.md)。

目标平台的 App ID / SDK Key 写入宿主 `BuildConfig`（或现有配置类）：

```kotlin
buildConfigField("String", "MAX_SDK_KEY", "\"${...}\"")
buildConfigField("String", "TOPON_APP_ID", "\"${...}\"")
buildConfigField("String", "TOPON_APP_KEY", "\"${...}\"")
buildConfigField("String", "TRAD_PLUS_ID", "\"${...}\"")
```

## 4. 宿主广告结构（按 pdf06）

三层，不要合成一层，也不要再造一套枚举。

```
AdCallbackImp  : AdCallback     // 广告位 val、凭证、布局、埋点、canLoadAd
AdManager                       // 门面 + clickFullScreenAd / fullAdInShowing
页面 / BaseActivity             // 只调 AdManager.showAd / checkAndLoadAd
```

### 4.1 AdCallbackImp

`object AdCallbackImp : {AdCallback}()`。广告位 **只定义在这里**，业务侧写 `AdCallbackImp.Start`，不要再写 `AdManager.AdPlace`。

```kotlin
object AdCallbackImp : /* 当前 AAR 的 AdCallback */() {
    val Start = AdPlace("xxxStart", listOf(AdFormat.OPEN, AdFormat.INTERSTITIAL), listOf("xxxStart", "xxxConnect", "xxxExtra"))
    val Connect = AdPlace("xxxConnect", listOf(AdFormat.INTERSTITIAL), listOf("xxxConnect", "xxxExtra"))
    val Extra = AdPlace("xxxExtra", listOf(AdFormat.INTERSTITIAL), listOf("xxxExtra", "xxxConnect"))
    val Home = AdPlace("xxxHome", listOf(AdFormat.NATIVE), null)
    val HomeBan = AdPlace("xxxHomeBan", listOf(AdFormat.BANNER), null)
    val Reward = AdPlace("xxxInc", listOf(AdFormat.REWARDED), null)

    override fun adPlaces() = listOf(Start, Connect, Extra, Home, HomeBan, Reward)
    override fun getTradplusAppId() = BuildConfig.TRAD_PLUS_ID   // 不接 TP → ""
    override fun getMaxID() = ""                                  // 不接 MAX → ""
    override fun getLocalAdConfigFileName() = "adConfig.json"
    override fun getRemoteAdConfigKey() = "full_ad_list"         // 以宿主 Remote Config 为准
    override fun getAdLoadMode() = AdLoadMode.Multi
}
```

- `askAdmobEcpm`：仅 **AdMob + Multi**；切走 AdMob 可删旧比价 jar。TradPlus 比价走 `compare_price`。
- `canForceCloseApplovinAd`：仅仍含 MAX 时按标志位返回；切走 MAX 可保持默认 `true`。
- `canReportAdmobImpression`：仅 AdMob；问运营是否已开自动收集。
- `getNativeAdStyle`：见 §5。
- `canLoadAd`：VPN / 白名单 / IP 拦截等宿主规则放这里。

Manifest：

```xml
<meta-data
    android:name="{完整类名.AdCallbackImp}"
    android:value="{namespace}" />
```

`android:value` = 打包时 `namespace`。AdMob 另加 `com.google.android.gms.ads.APPLICATION_ID`。合并冲突见 [reference-pitfalls.md](reference-pitfalls.md)。

### 4.2 AdManager 门面

只转发 `AdCallbackImp`，并持有宿主 UI 标志位。**禁止**再定义 `enum class AdPlace`、`@IntDef NativeType`。

```kotlin
fun checkAndLoadAd(vararg adPlaces: AdPlace) {
    if (adPlaces.isEmpty()) AdCallbackImp.loadAd() else AdCallbackImp.loadAd(*adPlaces)
}

fun showAd(..., adPlace: AdPlace, navType: NativeType = NativeType.BIG, ...): Boolean {
    return when {
        adPlace.adTypeList.any { it == AdFormat.NATIVE || it == AdFormat.BANNER } ->
            AdCallbackImp.showNavOrBan(activity, adPlace, navType, true, adContainer!!)
        adPlace.adTypeList.contains(AdFormat.REWARDED) ->
            AdCallbackImp.showReward(activity, adPlace) { ... }
        else ->
            AdCallbackImp.showOpenOrInt(activity, adPlace, fullCallback)
    }
}
```

原生样式直接传 AAR 的 `NativeType`（`BIG` / `SMALL`），不要自己映射 0/1。

### 4.3 页面接入

- 开屏/插页/激励：`AdManager.showAd(this, AdCallbackImp.Start, onFullAdCallBack = ...)`
- 原生/Banner：页面实现 `AdInterface.getAdParams()`，`BaseActivity.onStart` 找 `R.id.fl_ad` 再 `showAd`
- `AdParams(adPlace, nativeType = NativeType.BIG, isShowAd, onShowAd)`

## 5. 原生布局

每种 `NativeType` 两套 layout，**控件 ID 必须相同**：

| 参数 | AdMob | MAX / TopOn / TradPlus |
|------|--------|-------------------------|
| layout | `adMobLayoutResId` | `otherLayoutResId` |
| 根节点 | `com.google.android.gms.ads.nativead.NativeAdView` | 普通 ViewGroup |
| 媒体 | `com.google.android.gms.ads.nativead.MediaView` | `FrameLayout`（id 仍是 media_view） |

```kotlin
NativeAdStyle(
    R.layout.layout_nav_admob_big,  // AdMob
    R.layout.layout_nav_tp_big,     // 其它
    R.id.tv_top, R.id.tv_bottom, R.id.iv_icon, R.id.tv_button, R.id.media_view,
)
```

小样式无媒体时 `mediaViewId = View.NO_ID`。

## 6. 广告配置 JSON

必须同时有 **测试** 与 **正式** 配置（本地 assets + Remote Config 同结构）。`adPlace` 字符串 = `AdCallbackImp` 里 `AdPlace.label`。

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
| TradPlus | **必须** `tradplus` | 不会推断 |

切走某平台时，删掉或改写该平台的 `adInfos`。

## 7. 埋点与广告逻辑

改依赖前先定位旧 `AdManager` 标志位、`AppObserver`、启动页。这些是宿主 UI 状态，**不要跟着旧 AdManager 一起删**。细则见 [reference-host-logic.md](reference-host-logic.md)。

原项目埋点迁到 `AdCallbackImp`（`getAdEvent()` + `onAdShow` / `onAdClick` / `onAdPaid`）。插页/开屏/原生/Banner 展示成功若原项目是宿主自己报的，保持仍由宿主报。

## 8. ProGuard + 坑

正式包按 **仍启用的平台** keep，规则见 [reference-deps.md](reference-deps.md) 与 [reference-pitfalls.md](reference-pitfalls.md)。

常见必做：

- 含 TradPlus → keep `com.tradplus.**` + `com.tradplus.adapter.**` + `com.tp.compareprice.**`，且必须接入 `compare_price`
- 含 MAX → keep `com.applovin.**`
- 含 TopOn → keep `com.thinkup.**`
- 始终 keep `AdCallbackImp` 与 `{namespace}open.**`
- 换包名 → `package_name` 已含正式包并 **重打 AAR**

## 9. 验收

| 场景 | 期望 |
|------|------|
| debug / release 冷启 | 不崩（TradPlus 检查 compare_price；无 TTMultiProvider ClassNotFound） |
| 开屏 / 插页 | 目标平台有填充与展示；log 无「加载adapter文件发生错误」 |
| 首页原生 | 连续可展示；TradPlus 无隔次空壳 |
| 旧平台已删除时 | 无旧 SDK 类引用、无旧 unit 请求 |
| 启动页冷/热启动 | 进度条、开屏展示/关闭跳转与切前一致 |
| 启动页点击全屏广告 | 不立刻 `go()`；外跳回来不热启动套娃 |

## 10. Agent 约束

1. 先确认目标平台，不要默认 TradPlus。  
2. 不要只换 AAR 不改依赖。换 AAR 后必须先识别 `{namespace}open` 类名。  
3. 不要再造 `AdPlace` enum 或 `NativeType` IntDef；广告位挂 `AdCallbackImp`，样式用 AAR 的 NativeType。  
4. 目标含 TradPlus 时不要漏 `compare_price` / `adapter-util`；adapter 版本必须与主包对齐。  
5. 不要省略仍启用平台的正式包 keep。  
6. TopOn / TradPlus 的 `adConfig` 不要省略对应 `"platform"`。  
7. 不要漏把正式包名写入 `package_name`。  
8. 中介版本以运营与 **打包脚本打印**为准；不要抄 `*.66.4.42.1.1.100` 空壳坐标。  
9. 信息不全先问；不要改无关宿主路径。  
10. 不要把 `clickFullScreenAd` / `fullAdInShowing` / 启动页热启动随旧 `AdManager` 删掉。
