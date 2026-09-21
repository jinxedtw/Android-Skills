# 宿主启动页 / 热启动 / 广告标志位

切换聚合时，广告 SDK 换成 adSdk，但 **启动页节奏、热启动、退后台关广告** 仍是宿主逻辑。

adsdk 内部 `AppObserver` 只做：前后台切换时允许/禁止原生刷新，以及退后台强制关掉第三方广告 Activity。它 **不会** 帮宿主开 Splash、发召回通知、防开屏连跳。

写法以 **M366** 为准：标志位放宿主 `AdState`（或同等门面），广告位放 `AdCallbackImp`，页面只调门面。

## 改之前先搜

记下读写点再搬家（不要先删旧 `AdManager`）：

- `clickFullScreenAd`
- `fullAdInShowing`
- `fullScreenAdClickLeftApp`（点击全屏广告后是否已离开应用）
- `clickOpenMaxAd`（仅 MAX）
- `adIsInShow` / `isInShowAd` / `canCallback`
- `canAnimResume`
- `canShowHot`
- `haveOpenAd` / `goWithAd`
- `AppLovinFullscreenActivity` / `AdSplashActivity` / `tpnClose`

## 标志位（必须按此写）

宿主单独放一个 object（M366 是 `AdState`），不要散落在各 `*AdImp` 里：

```kotlin
object AdState {
    var clickFullScreenAd = false

    /** 全屏广告点击后是否已离开应用（用于区分「点击但未外跳」与「点击并跳转外部」） */
    var fullScreenAdClickLeftApp = false
    var fullAdInShowing = false
    var clickOpenMaxAd = false
}
```

| 标志 | 谁置 true | 谁置 false | 用途 |
|------|-----------|------------|------|
| `clickFullScreenAd` | 开屏/插页 `onAdClick` | 启动页 `onResume`；`onAdClose`；`goWithAd` 回调里 | 点了全屏广告 |
| `fullAdInShowing` | `onAdClick` | `onAdClose` | `ON_STOP` 发广告召回通知 |
| `fullScreenAdClickLeftApp` | `ON_STOP` 且 `fullAdInShowing && clickFullScreenAd` | 启动页 `onCreate`；`goWithAd` 里 `go()` 前后；**MAX 点击时在 `canForceCloseApplovinAd` 里清掉** | 点了且外跳：回来不要立刻 `go()`。点了但还在 AppLovin 页：必须是 false，关闭后仍 `go()` |
| `clickOpenMaxAd` | 开屏/插页 `onAdClick`，且栈里同时有 `AppLovinFullscreenActivity` + Splash | `onAdShow` | 点了 MAX 全屏：**不要** force dismiss，否则热启动套娃 |

`clickOpenMaxAd` 只属于 MAX中介。目标不含 MAX中介 时删除它和对 `AppLovinFullscreenActivity` 的引用。前三个 **所有平台都要留**。

## 接到 AdCallbackImp

```kotlin
override fun onAdClick(..., type: AdFormat, platform: AdPlatform) {
    AdState.fullAdInShowing = true
    if (type == AdFormat.INTERSTITIAL || type == AdFormat.OPEN) {
        AdState.clickFullScreenAd = true
        AdState.clickOpenMaxAd =
            ActivityUtils.isActivityExistsInStack(AppLovinFullscreenActivity::class.java) &&
                ActivityUtils.isActivityExistsInStack(SplashActivity::class.java)
    }
}

override fun onAdClose(adType: AdFormat) {
    super.onAdClose(adType)
    AdState.fullAdInShowing = false
    AdState.clickFullScreenAd = false
}

override fun onAdShow(adPlace: AdPlace, adType: AdFormat) {
    AdState.clickOpenMaxAd = false
    // 开屏/插页/原生/Banner 展示成功埋点按原项目放这里
}

override fun onAdActivityForceClose(activity: Activity) {
    if (activity is AppLovinFullscreenActivity) {
        if (!AdState.clickOpenMaxAd) {
            // 点击MAX开屏广告不自动关闭,避免无限热启动
            SplashActivity.adIsInShow = false
        }
    } else {
        SplashActivity.adIsInShow = false
    }
}

override fun canForceCloseApplovinAd(): Boolean {
    if (AdState.clickOpenMaxAd) {
        AdState.fullScreenAdClickLeftApp = false
    }
    return !AdState.clickOpenMaxAd
}
```

切走 MAX 后：`onAdActivityForceClose` 只留 `adIsInShow = false`；`canForceCloseApplovinAd` 保持默认 `true`，不要再引用 `AppLovinFullscreenActivity`。

## 启动页（冷启动）

```
onCreate / initPage
  → AdCallbackImp.onHotStart()
  → AdState.fullScreenAdClickLeftApp = false
  → 进度动画 + loadAd(Start, ...)
  → 有开屏缓存 ? goWithAd() : go()

goWithAd
  → adIsInShow 防重入
  → showOpenOrInt(Start)
  → onAdClosed / onAdShowFail：
        if (!AdState.fullScreenAdClickLeftApp) go()
        AdState.fullScreenAdClickLeftApp = false
        AdState.clickFullScreenAd = false
  → show 返回 false：直接 go()

onResume
  → AdState.clickFullScreenAd = false
  → canAnimResume 则重跑动画
```

通知权限、VPN 上报、引导页 / Main 跳转、`OutOpenActivity` 的 action 透传，一律按原项目保留。

## 原生 / Banner 页

页面实现 `AdInterface`，`getAdParams()` 返回 `AdParams(adPlace = AdCallbackImp.HomeBan)`。  
`BaseActivity.onStart` 找 `R.id.fl_ad`，关闭位则 GONE，否则 `AdManager.showAd(..., adContainer = fl_ad)`。

## 热启动

宿主 `AppObserver.ON_START`（`canShowHot == true`）**保持原项目判断**，不要自行加各广告 SDK 包名前缀。

adsdk 自己的 `AppObserver` 会在退后台时强制关掉第三方广告 Activity（`AppLovinFullscreenActivity` 除外，由 `canForceCloseApplovinAd()` 决定）。因此宿主热启动一般只需：

- 当前已是 Splash / 引导 / OutOpen → 不再开 Splash
- 原项目若有 `isActivityExistsInStack(AppLovinFullscreenActivity)`，原样保留
- `canShowHot == false`：本次数一次（系统相册、文件选择）

不要改成 `topName.startsWith("com.applovin.")` / `com.facebook.ads` / `com.vungle.ads` 这类清单。

`ON_STOP`：

```kotlin
SplashActivity.canAnimResume = true
if (AdState.fullAdInShowing && AdState.clickFullScreenAd) {
    AdState.fullScreenAdClickLeftApp = true
}
if (canShowHot && AdState.fullAdInShowing) {
    // 广告召回通知
}
```

第三方广告 Activity 的 finish / AppLovin `dismiss` 交给 **adsdk 自己的 AppObserver**，宿主不要再扫一遍。MAX 是否 dismiss 由 `canForceCloseApplovinAd()` 决定；复位 `adIsInShow` 只在 `onAdActivityForceClose` 里做。

## 通知拉起

`OutOpenActivity` 从通知进来时先关广告页再进 Splash。切走对应平台后删对应分支，「先关广告再进启动页」要留。

## 切平台时怎么删

| 切走 | 可删 | 必须留 |
|------|------|--------|
| MAX | `clickOpenMaxAd`、`AppLovinFullscreenActivity`、`dismiss("app_force_dismiss")` | 热启动开 Splash、`clickFullScreenAd`、关广告后再 `go()` |
| Bigo 中介 | `AdSplashActivity`、`tpnClose` | 同上 |
| 任意平台 | 旧 `*AdImp` 里对标志位的赋值 | 改接到 `AdCallbackImp` 同等时机 |
