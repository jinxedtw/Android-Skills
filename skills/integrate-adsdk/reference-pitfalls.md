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

adsdk 在 TradPlus `init` 时：

```kotlin
Class.forName("com.tp.compareprice.ComparePriceUtil")
```

| 场景 | 结果 |
|------|------|
| debug（通常未 minify） | 类名保留 → 正常 |
| release + R8 | 类被裁剪/改名 → 失败 |

依赖写了 aar **不等于**正式包一定有该类。必须同时 keep `com.tp.compareprice.**`。切走 TradPlus 后应删除该 aar 与 keep。

---

## 3. 原生广告隔次失败（TradPlus）

TradPlus 同一广告位是 **全局单例**。adsdk 必须按 `unitId` 复用 `TPNative`，展示后在同一实例 `loadAd()`，禁止再 `new`。

MAX / AdMob 无此限制，从它们切到 TradPlus 时「看起来没改原生却隔次空壳」。

宿主循环 Banner（如 2 页 info|ad）：

- **不要**在 `bindData` 里 `showNavOrBan`
- **要**在广告页 `onPageSelected` 后再 show
- 容器/缓存未就绪可短重试；离开广告页取消任务

---

## 4. 有缓存但不展示 / platform 写错

`AdManager.resolvePlatform`：

- 显式 `platform`：`admob`/`google`、`max`/`applovin`、`topon`/`tpn`、`tradplus`/`tp`
- 否则：`ca-app-pub*` → AdMob，其余 → **MAX**

因此：

- TopOn unit **必须** `"platform": "topon"`
- TradPlus unit **必须** `"platform": "tradplus"`
- 切走 MAX 后，未标 platform 的非 AdMob id 仍会被当成 MAX → 无填充或走错 SDK

---

## 5. 运行时包名校验失败

```properties
package_name = com.test.app,{正式applicationId}
```

白名单不含正式包名 → 校验失败。改白名单后必须 **重打 AAR**。测试包和正式包都要写。

---

## 6. 凭证与 enable_platform 不一致

AAR 里有该平台代码，但 AdCallback 对应字段为空：

| 平台 | 空凭证时 |
|------|----------|
| MAX | 日志：已接入 MAX，但未配置 `maxID`，init 直接 return |
| TopOn | 未配置 `toponAppId` / `toponAppKey`，init return |
| TradPlus | 未配置 `tradplusAppId`，init return |

反过来说：AAR 没打该平台，宿主却留着旧 unit / 旧依赖，也会请求失败或引入无用体积。

---

## 7. 切走平台时漏删专用逻辑

| 逻辑 | 属于 | 切走才删 |
|------|------|----------|
| `askAdmobEcpm` + AdMob 比价 jar | AdMob Multi | 切走 AdMob |
| `canForceCloseApplovinAd` / 退后台关 AppLovin 页 | MAX | 切走 MAX |
| `**/topon/custom/**` | TopOn | 切走 TopOn |
| Bigo 中介特殊处理 | 视中介清单 | 目标中介已不含 Bigo |
| `compare_price` | TradPlus | 切走 TradPlus |

启动页、冷热启动、`onHotStart` / `loadAd` / 展示关闭流程是 **宿主广告逻辑**，与平台无关，默认保留。

---

## 8. namespace / 公开 API 对不上

公开 API 包 = `{namespace}open`。Manifest `android:value` 必须等于打包时的 `namespace`。换 namespace 后宿主 import、实现类、meta-data 一起改。

---

## 9. AdMob 原生布局

AdMob 布局根节点必须是 `com.google.android.gms.ads.nativead.NativeAdView`。MAX / TopOn / TradPlus 走 `otherLayoutResId`。同一 `NativeType` 下控件 ID 保持一致。
