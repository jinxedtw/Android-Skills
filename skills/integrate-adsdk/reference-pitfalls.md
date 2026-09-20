# 切换广告聚合常见问题

## 1. 只换 AAR、不改宿主依赖

各平台 SDK 在 AAR 内是 `compileOnly`。`enable_platform` 决定 AAR **有没有**该平台代码；运行时类仍由宿主 Gradle 提供。

漏接 → `ClassNotFoundException` / `NoClassDefFoundError`。debug 可能碰巧能跑，release 必爆。

---

## 2. TradPlus 正式包崩溃：compare_price

仅目标含 `tradplus` 时出现。

```
IllegalStateException: 宿主未接入 compare_price-release.aar，
请添加: implementation(files("libs/compare_price-release.aar"))
```

adsdk 在 TradPlus `init` 时 `Class.forName("com.tp.compareprice.ComparePriceUtil")`。依赖写了 aar **不等于**正式包一定有该类，必须 keep `com.tp.compareprice.**`。切走 TradPlus 后删除该 aar 与 keep。

---

## 3. TradPlus「加载adapter文件发生错误：exception admob」

Adapter 版本没对上主包，或用了空壳坐标（如 `tradplus-googlex:2.66.4.42.1.1.100`）。空壳 AAR 只有 `app_name`，没有 `GoogleInitManager`。

处理：把所有 `com.tradplusad:tradplus-*` 改成 `{networkId}.{与 tradplus 主包相同的版本}`，并加 `adapter-util:1.0.1`。验证见 [reference-deps.md](reference-deps.md)。

---

## 4. 启动即崩：TTMultiProvider

```
java.lang.RuntimeException: Unable to get provider
com.bytedance.sdk.openadsdk.multipro.TTMultiProvider
```

Pangle Global SDK ≥ 4.1.0.0 已删除该类。旧 TradPlus pangle adapter 仍在自己的 Manifest 里注册。宿主覆盖：

```xml
<provider
    android:name="com.bytedance.sdk.openadsdk.multipro.TTMultiProvider"
    tools:node="remove" />
```

匹配 16.9+ 的 `tradplus-pangle:19.{tpVersion}` 通常已不再声明；保险起见可保留 remove。

---

## 5. Manifest merger：AudienceNetworkActivity configChanges

```
Attribute activity#com.facebook.ads.AudienceNetworkActivity@configChanges
from audience-network-sdk 与 tradplus-facebook 冲突
```

`tools:replace` 对「两个 library 互撞」经常不够，用完整 Facebook SDK 声明盖掉：

```xml
<activity
    android:name="com.facebook.ads.AudienceNetworkActivity"
    android:configChanges="keyboardHidden|orientation|screenSize|smallestScreenSize|screenLayout"
    android:exported="false"
    android:theme="@android:style/Theme.Translucent.NoTitleBar"
    tools:node="replace" />
```

根节点需要 `xmlns:tools="http://schemas.android.com/tools"`。

---

## 6. Manifest merger：Vungle warren receiver

旧 `tradplus-vunglex` 仍声明 Vungle 6.x：

- `com.vungle.warren.NetworkProviderReceiver`（有 intent-filter、无 `exported` → target 31 合并不过）
- `com.vungle.warren.ui.VungleActivity`

Vungle 7 包名是 `com.vungle.ads`，这些类不存在。宿主：

```xml
<activity android:name="com.vungle.warren.ui.VungleActivity" tools:node="remove" />
<receiver android:name="com.vungle.warren.NetworkProviderReceiver" tools:node="remove" />
```

---

## 7. 原生广告隔次失败（TradPlus）

TradPlus 同一广告位是 **全局单例**。adsdk 必须按 `unitId` 复用 `TPNative`，展示后在同一实例 `loadAd()`，禁止再 `new`。

宿主循环 Banner（如 2 页 info|ad）：

- **不要**在 `bindData` 里 `showNavOrBan`
- **要**在广告页 `onPageSelected` 后再 show

---

## 8. 有缓存但不展示 / platform 写错

`resolvePlatform`：

- 显式 `platform`：`admob`/`google`、`max`/`applovin`、`topon`/`tpn`、`tradplus`/`tp`
- 否则：`ca-app-pub*` → AdMob，其余 → **MAX**

因此 TopOn / TradPlus unit **必须**写 `"platform"`。切走 MAX 后，未标 platform 的非 AdMob id 仍会被当成 MAX。

---

## 9. 运行时包名校验失败

```properties
package_name = com.test.app,{正式applicationId}
```

白名单不含正式包名 → 校验失败。改白名单后必须 **重打 AAR**。

---

## 10. 凭证与 enable_platform 不一致

AAR 里有该平台代码，但 AdCallback 对应字段为空：MAX / TopOn / TradPlus 会打日志后 `init` 直接 return。

反过来说：AAR 没打该平台，宿主却留着旧 unit / 旧依赖，也会请求失败或引入无用体积。

---

## 11. namespace / 公开 API 对不上

公开 API 包 = `{namespace}open`。Manifest `android:value` 必须等于打包时的 `namespace`。换 AAR 后类名会变，宿主 import 必须跟着改，不要沿用上一份 AAR 的混淆名。

---

## 12. AdMob 原生布局

AdMob 布局根节点必须是 `NativeAdView`，媒体必须是 `MediaView`。其它平台走 `otherLayoutResId`，媒体用 `FrameLayout`。同一 `NativeType` 下控件 ID 保持一致。

---

## 13. 切走平台时漏删专用逻辑

| 逻辑 | 属于 | 切走才删 |
|------|------|----------|
| `askAdmobEcpm` + AdMob 比价 jar | AdMob Multi | 切走 AdMob |
| `canForceCloseApplovinAd` / 退后台关 AppLovin 页 | MAX | 切走 MAX |
| `**/topon/custom/**` | TopOn | 切走 TopOn |
| Bigo 中介特殊处理 | 视中介清单 | 目标中介已不含 Bigo |
| `compare_price` | TradPlus | 切走 TradPlus |

启动页、冷热启动、`onHotStart` / `loadAd` / 展示关闭流程是 **宿主广告逻辑**，与平台无关，默认保留。
