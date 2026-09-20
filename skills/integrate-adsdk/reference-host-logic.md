# 宿主启动页 / 热启动 / 广告标志位

切换聚合时，广告 SDK 换成 adSdk，但 **启动页节奏、热启动、退后台关广告** 仍是宿主逻辑。

adsdk 内部 `AppObserver` 只做：前后台切换时允许/禁止原生刷新，以及退后台强制关掉第三方广告 Activity。它 **不会** 帮宿主开 Splash、发召回通知、防开屏连跳。

写法以 pdf06 为准：标志位放宿主 `AdManager` 门面，广告位放 `AdCallbackImp`，页面只调门面。

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

## 标志位含义

| 标志 | 谁置 true | 谁置 false | 用途 |
|------|-----------|------------|------|
| `clickFullScreenAd` | 全屏 `onAdClick` | 启动页 `onResume`；关闭流程里复位 | 区分「点了广告」 |
| `fullAdInShowing` | `onAdClick` 或开屏/插页 `onAdShow` | `onAdClose` | `ON_STOP` 发广告召回通知 |
| `fullScreenAdClickLeftApp` | `ON_STOP` 时 `fullAdInShowing && clickFullScreenAd` | 启动页 `onCreate` / 关闭后 `go()` 前 | 点广告并外跳时，回来不要立刻 `go()` 套娃 |
| `clickOpenMaxAd` | MAX 开屏/插页点击，且栈里同时有 AppLovin 全屏 + Splash | 下次 show MAX 全屏前 | `ON_STOP` **不要** dismiss AppLovin |

`clickOpenMaxAd` 只属于 MAX。目标不含 MAX 时删除它。前三个 **所有平台都要留**。

## 接到 AdCallbackImp

```kotlin
override fun onAdClick(..., type: AdFormat, platform: AdPlatform) {
    AdManager.fullAdInShowing = true
    if (type == AdFormat.OPEN || type == AdFormat.INTERSTITIAL || type == AdFormat.REWARDED) {
        AdManager.clickFullScreenAd = true
        // 仍含 MAX 且栈里同时有 AppLovinFullscreenActivity + Splash → clickOpenMaxAd = true
    }
}

override fun onAdClose(adType: AdFormat) {
    super.onAdClose(adType)
    AdManager.fullAdInShowing = false
    AdManager.clickFullScreenAd = false
}

override fun onAdShow(adPlace: AdPlace, adType: AdFormat) {
    if (adType == AdFormat.OPEN || adType == AdFormat.INTERSTITIAL) {
        AdManager.fullAdInShowing = true
    }
}

override fun onAdActivityForceClose(activity: Activity) {
    SplashActivity.adIsInShow = false
}

override fun canForceCloseApplovinAd(): Boolean = !clickOpenMaxAd  // 无 MAX 时保持 true
```

## 启动页（冷启动）

```
onCreate / initPage
  → AdCallbackImp.onHotStart()
  → 复位 fullScreenAdClickLeftApp
  → 进度动画 + AdManager.checkAndLoadAd(Start, Connect, Home, ...)
  → 有开屏缓存 ? goWithAd() : go()

goWithAd
  → adIsInShow 防重入
  → AdManager.showAd(this, AdCallbackImp.Start, onFullAdCallBack)
  → onAdClose / onAdShowFail：!fullScreenAdClickLeftApp 才 go()
  → show 返回 false：直接 go()

onResume
  → clickFullScreenAd = false
  → canAnimResume 则重跑动画
```

通知权限、VPN 上报、引导页 / Main 跳转、`OutOpenActivity` 的 action 透传，一律按原项目保留。

## 原生 / Banner 页

页面实现 `AdInterface`，`getAdParams()` 返回 `AdParams(adPlace = AdCallbackImp.HomeBan)`。  
`BaseActivity.onStart` 找 `R.id.fl_ad`，关闭位则 GONE，否则 `AdManager.showAd(..., adContainer = fl_ad)`。

## 热启动

宿主 `AppObserver.ON_START`（`canShowHot == true`）：

- 当前已是 Splash / 引导 / OutOpen → 不再开 Splash
- 栈里已有全屏广告 Activity → 不再开 Splash（按广告 SDK 包名前缀判断，如 `com.tradplus.ads`、`com.google.android.gms.ads`、`com.facebook.ads`、`com.bytedance.sdk`、`com.vungle.ads`、`sg.bigo.ads`、`com.mbridge.msdk`、`com.unity3d.ads`、`com.fyber`、`com.applovin.adview`）
- `canShowHot == false`：本次数一次（系统相册、文件选择）

`ON_STOP`：

1. `Splash.canAnimResume = true`
2. `fullAdInShowing && clickFullScreenAd` → `fullScreenAdClickLeftApp = true`
3. `fullAdInShowing` → 广告召回通知
4. 非宿主广告 Activity：MAX 交给 adsdk + `canForceCloseApplovinAd`；宿主在 `onAdActivityForceClose` 复位 `adIsInShow`

## 通知拉起

`OutOpenActivity` 从通知进来时先关广告页再进 Splash。切走对应平台后删对应分支，「先关广告再进启动页」要留。

## 切平台时怎么删

| 切走 | 可删 | 必须留 |
|------|------|--------|
| MAX | `clickOpenMaxAd`、`AppLovinFullscreenActivity`、`dismiss("app_force_dismiss")` | 热启动开 Splash、`clickFullScreenAd`、关广告后再 `go()` |
| Bigo 中介 | `AdSplashActivity`、`tpnClose` | 同上 |
| 任意平台 | 旧 `*AdImp` 里对标志位的赋值 | 改接到 `AdCallbackImp` 同等时机 |
