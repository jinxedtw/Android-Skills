# 宿主启动页 / 热启动 / 广告标志位

切换聚合时，广告 SDK 换成 adSdk，但 **启动页节奏、热启动、退后台关广告** 仍是宿主逻辑。旧代码多在宿主 `AdManager` + `AppObserver` + Splash（参考 `com/ai/smart/AppObserver.kt`）。

adsdk 的 `AppObserver` 只做：前后台切换时允许/禁止原生刷新，以及退后台强制关掉第三方广告 Activity。它 **不会** 帮宿主开 Splash、发召回通知、防开屏连跳。

## 改之前先搜

在宿主全局搜这些名字，记下读写点再搬家（不要先删旧 `AdManager`）：

- `clickFullScreenAd`
- `fullAdInShowing`
- `clickOpenMaxAd`
- `adIsInShow` / `isInShowAd` / `canCallback`
- `canAnimResume`
- `canShowHot`
- `haveOpenAd` / `canAccelerate` / `goWithAd`
- `AppLovinFullscreenActivity` / `AdSplashActivity` / `tpnClose`

## 标志位含义

| 标志 | 谁置 true | 谁置 false | 用途 |
|------|-----------|------------|------|
| `clickFullScreenAd` | 全屏广告 `onAdClick` | 启动页 `onResume` | 开屏关闭后不立刻 `go()`；插页关闭后若用户已点广告，把目标功能挂到 `lostFunction`，回来再跳 |
| `fullAdInShowing` | 全屏点击或展示中 | `onAdClose` / hidden | `ON_STOP` 时发「广告召回」通知，而不是普通退后台通知 |
| `clickOpenMaxAd` | MAX 开屏/插页点击，且栈里同时有 `AppLovinFullscreenActivity` + Splash | 下次 `show` MAX 全屏前 | `ON_STOP` **不要** `dismiss` AppLovin，否则热启动死循环 |

`clickOpenMaxAd` 只属于 MAX。目标不含 MAX 时删除它和对 `AppLovinFullscreenActivity` 的引用。`clickFullScreenAd` / `fullAdInShowing` **所有平台都要留**。

## 接到 AdCallback

旧逻辑写在各 `*AdImp` 的 Max/AdMob listener 里。切走后这些 Imp 会删掉，必须改接到：

```kotlin
override fun onAdClick(..., type: AdFormat, platform: AdPlatform) {
    if (type == AdFormat.OPEN || type == AdFormat.INTERSTITIAL || type == AdFormat.REWARDED) {
        clickFullScreenAd = true
        fullAdInShowing = true
        if (/* 目标仍含 MAX */ platform == AdPlatform.Max
            && 栈含 AppLovinFullscreenActivity
            && 栈含 Splash) {
            clickOpenMaxAd = true
        }
    }
}

override fun onAdClose(adType: AdFormat) {
    fullAdInShowing = false
}

override fun canForceCloseApplovinAd(): Boolean = !clickOpenMaxAd

override fun onAdActivityForceClose(activity: Activity) {
    SplashActivity.adIsInShow = false
}
```

## 启动页（冷启动）

保持原顺序，只替换调用目标：

```
onCreate
  → AdCallback.onHotStart()     // 清过期缓存、拉 Remote Config、跨天重置全屏计数
  → 进度动画 + loadAd(Start 及业务预加载位)
  → 有开屏缓存 ? goWithAd() : go()

goWithAd
  → adIsInShow 防重入
  → showOpenOrInt(Start)
  → onAdClosed / onAdShowFail：!clickFullScreenAd 才 go()
  → show 失败：直接 go()

onResume
  → clickFullScreenAd = false
  → canAnimResume 则重跑动画
```

通知权限、VPN 上报、引导页 / Main 跳转、`OutOpenActivity` 的 action 透传，一律按原项目保留。

## 热启动

宿主 `AppObserver.ON_START`（`canShowHot == true`）：

- 当前已是 Splash / 引导 / OutOpen → 不再开 Splash
- 栈里已有全屏广告 Activity → 不再开 Splash  
  原 MAX 工程：`!isActivityExistsInStack(AppLovinFullscreenActivity)`  
  切走 MAX 后：不要删掉这层判断；改成「栈内是否还有广告 SDK 的 Activity」（包名见 adsdk `AppObserver.adPackageList`，含 `com.tradplus.ads`、`com.applovin.adview`、`sg.bigo.ads` 等）
- `canShowHot == false`：本次数一次，下次才允许热启动（系统相册、文件选择等会先把 `canShowHot` 设 false）

`ON_STOP`：

1. `Splash.canAnimResume = true`
2. `fullAdInShowing` → 广告召回通知，并清掉该标志
3. 遍历非宿主 Activity：MAX → 受 `clickOpenMaxAd` 约束的 `dismiss`；Bigo 开屏 → `onAdSkipped`；其余 `finish()`，同时把 `adIsInShow = false`

adsdk 内部也会在 `ON_STOP` 关第三方广告页。宿主不要再无条件 `finish` MAX 页，否则会绕过 `canForceCloseApplovinAd`。正确做法：MAX 关页交给 adsdk + `canForceCloseApplovinAd()`；宿主只在 `onAdActivityForceClose` 里复位启动页状态。

## 通知拉起

`OutOpenActivity` 从通知进来时，会先关 `AppLovinFullscreenActivity` / Bigo 开屏再进 Splash。切走对应平台后删对应分支，但「先关广告再进启动页」这条要留。

## 切平台时怎么删

| 切走 | 可删 | 必须留 |
|------|------|--------|
| MAX | `clickOpenMaxAd`、`AppLovinFullscreenActivity`、`dismiss("app_force_dismiss")` | 热启动开 Splash、`clickFullScreenAd`、关广告后再 `go()` |
| Bigo 中介 | `AdSplashActivity`、`tpnClose` | 同上 |
| 任意平台 | 旧 `*AdImp` 里对标志位的赋值 | 改接到 `AdCallback` 同等时机 |
