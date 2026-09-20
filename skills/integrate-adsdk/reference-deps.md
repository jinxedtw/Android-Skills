# 宿主依赖参考

版本号会变。**优先使用 adsdk 打包结束时脚本打印的 dependencies / repositories。** 下文只给形态，禁止当死坐标全量粘贴。

只加运营后台 **已开启** 的广告源。

## 按平台：必须加什么

### AdMob（`enable_platform` 含 `admob`）

打包脚本会打印 AdMob SDK + `admob_mediation` Adapter。

```kotlin
implementation("com.google.android.gms:play-services-ads:{version}")
// 再加脚本打印的各中介 Adapter
```

常见额外仓库（有对应中介才加）：

- Mintegral：`https://dl-maven-android.mintegral.com/repository/mbridge_android_sdk_oversea`
- InMobi：`https://android-sdk.is.com`
- Pangle：`https://artifact.bytedance.com/repository/pangle`

### MAX（`enable_platform` 含 `max`）

打包脚本会打印 MAX SDK + `max_mediation` Adapter。

```kotlin
implementation("com.applovin:applovin-sdk:{version}")
// 再加脚本打印的 com.applovin.mediation:* Adapter
```

Bigo 是否接入看 `max_mediation` 是否包含 `bigo`。

### TopOn（`enable_platform` 含 `topon`）

脚本 **不打印** 中介坐标，会提示联系运营。宿主自行加入运营提供的 TopOn / ThinkUp 依赖，并加仓库：

```kotlin
maven { url = uri("https://jfrog.anythinktech.com/artifactory/overseas_sdk") }
```

### TradPlus（`enable_platform` 含 `tradplus`）

脚本通常只打印主包 + `compare_price`。Adapter / 仓库按运营后台已开启广告源自行加。

```kotlin
implementation(files("libs/adSdk-release.aar"))
implementation(files("libs/compare_price-release.aar")) // 必接
implementation("com.tradplusad:tradplus:{version}")
// 以下仅为形态；网络与版本以运营 + 当前 TP 文档为准
// AdMob / Meta / Pangle / UnityAds / Fyber / Mintegral / Liftoff / Bigo / Cross Promotion / TP Exchange
```

`compare_price-release.aar` 源文件：`adsdk/ad/libs/compare_price-release.aar`。

TradPlus 形态示例（**版本勿照抄**）：

```kotlin
implementation("com.google.android.gms:play-services-ads:{version}")
implementation("com.tradplusad:tradplus-googlex:{version}")
implementation("com.facebook.android:audience-network-sdk:{version}")
implementation("com.tradplusad:tradplus-facebook:{version}")
implementation("com.tradplusad:tradplus-pangle:{version}")
implementation("com.pangle.global:pag-sdk:{version}")
implementation("com.tradplusad:tradplus-unity:{version}")
implementation("com.unity3d.ads:unity-ads:{version}")
implementation("com.fyber:marketplace-sdk:{version}")
implementation("com.tradplusad:tradplus-fyber:{version}")
implementation("com.tradplusad:tradplus-mintegralx_overseas:{version}")
implementation("com.mbridge.msdk.oversea:mbridge_android_sdk:{version}")
implementation("com.tradplusad:tradplus-vunglex:{version}")
implementation("com.vungle:vungle-ads:{version}")
implementation("com.bigossp:bigo-ads:{version}")
implementation("com.tradplusad:tradplus-bigo:{version}")
implementation("com.tradplusad:tradplus-crosspromotion:{version}")
implementation("com.tradplusad:tp_exchange:{version}")
```

TradPlus 常见仓库：`google()`、`mavenCentral()`、`https://jitpack.io`、Mintegral overseas、Pangle。其余以打包脚本 / 运营文档为准。

## 切走某平台时移除

| 切走 | 移除 |
|------|------|
| MAX | `com.applovin:applovin-sdk`、所有 `com.applovin.mediation:*` |
| TopOn | `com.thinkup.sdk:*`、宿主源码 `**/topon/custom/**`（Custom Bidding Adapter 等） |
| AdMob | `play-services-ads` / `play-services-ads-lite` 及 `com.google.ads.mediation:*`（若 UMP 仍要同意弹窗，评估是否保留 ads） |
| TradPlus | `com.tradplusad:*`、`tp_exchange`、`compare_price-release.aar`、各广告源 SDK（若无其它平台再用） |

多平台并存时只删「确认不用」的那一层，不要误删仍被另一平台使用的广告源 SDK（如 AdMob SDK 可能同时被 MAX/TP 中介用到）。

## BuildConfig 字段

按启用平台添加，未启用不加：

```kotlin
buildConfigField("String", "MAX_SDK_KEY", "\"...\"")
buildConfigField("String", "TOPON_APP_ID", "\"...\"")
buildConfigField("String", "TOPON_APP_KEY", "\"...\"")
buildConfigField("String", "TRAD_PLUS_ID", "\"...\"")
```

写入宿主现有配置类即可，不要假设某个业务工程的路径。

## ProGuard（按仍启用的平台追加）

```proguard
# MAX
-keep class com.applovin.** { *; }
-dontwarn com.applovin.**

# TopOn / ThinkUp
-keep class com.thinkup.** { *; }
-dontwarn com.thinkup.**

# TradPlus
-keep public class com.tradplus.** { *; }
-keep class com.tradplus.ads.** { *; }

# TradPlus 比价（正式包 Class.forName，漏 keep 必崩）
-keep class com.tp.compareprice.** { *; }
-dontwarn com.tp.compareprice.**
```

广告源（Meta / Pangle / Mintegral 等）keep 以各网络文档 + 打包脚本为准。

## adsdk 侧相关路径

| 路径 | 说明 |
|------|------|
| `adsdk/project.config` | `enable_platform` / `package_name` / `namespace` / 中介 |
| `adsdk/scripts/configure_project.py` | 打印宿主依赖与混淆 |
| `adsdk/ad/libs/compare_price-release.aar` | TradPlus 比价库 |
| `adsdk/ad/src/admob/` `max/` `topon/` `tradplus/` | 各平台实现，未 enable 的不会打进 AAR |
| `adsdk/aar-records/{代号}/` | 归档 AAR |
| `adsdk/README.markdown` | 通用 adSdk 说明（AdCallback / 埋点 / JSON） |
