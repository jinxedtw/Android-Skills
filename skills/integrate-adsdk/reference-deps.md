# 宿主依赖参考

版本号会变。**优先使用 adsdk 打包结束时脚本打印的 dependencies / repositories。** 下文只给形态，禁止当死坐标全量粘贴。

只加运营后台 **已开启** 的广告源。

## 按平台：必须加什么

### AdMob（`enable_platform` 含 `admob`）

打包脚本会打印 AdMob SDK + `admob_mediation` Adapter。

```kotlin
implementation("com.google.android.gms:play-services-ads:{version}")
```

常见额外仓库（有对应中介才加）：

- Mintegral：`https://dl-maven-android.mintegral.com/repository/mbridge_android_sdk_oversea`
- InMobi：`https://android-sdk.is.com`
- Pangle：`https://artifact.bytedance.com/repository/pangle`

### MAX（`enable_platform` 含 `max`）

```kotlin
implementation("com.applovin:applovin-sdk:{version}")
// 再加脚本打印的 com.applovin.mediation:* Adapter
```

### TopOn（`enable_platform` 含 `topon`）

脚本 **不打印** 中介坐标。加运营提供的 ThinkUp 依赖，并加仓库：

```kotlin
maven { url = uri("https://jfrog.anythinktech.com/artifactory/overseas_sdk") }
```

### TradPlus（`enable_platform` 含 `tradplus`）

```kotlin
implementation(files("libs/adSdk-release.aar"))
implementation(files("libs/compare_price-release.aar"))
implementation("com.tradplusad:tradplus:{tpVersion}")
implementation("com.tradplusad:adapter-util:1.0.1")   // 16.9+ 各 adapter POM 都依赖
```

`compare_price-release.aar` 源文件：`adsdk/ad/libs/compare_price-release.aar`。

#### Adapter 版本必须与主包对齐

Maven Central 坐标是 `{networkId}.{tradplusVersion}`：

| artifact | 示例（主包 `16.9.0.1`） |
|----------|-------------------------|
| `tradplus-googlex` | `2.16.9.0.1` |
| `tradplus-facebook` | `1.16.9.0.1` |
| `tradplus-pangle` | `19.16.9.0.1` |
| `tradplus-unity` | `5.16.9.0.1` |
| `tradplus-fyber` | `24.16.9.0.1` |
| `tradplus-mintegralx_overseas` | `18.16.9.0.1` |
| `tradplus-vunglex` | `7.16.9.0.1` |
| `tradplus-bigo` | `57.16.9.0.1` |
| `tradplus-crosspromotion` | `27.16.9.0.1` |
| `tp_exchange` | `40.16.9.0.1` |

主包 `16.7.20.1` → googlex `2.16.7.20.1`，依此类推。

**禁止**使用 `2.66.4.42.1.1.100` 这类坐标：Maven 上可能有 POM，但 AAR 几乎是空壳（只有 `app_name`），运行时 TradPlus 打：

```
TradPlusLog  加载adapter文件发生错误：exception admob
```

接入后立刻检查 googlex AAR 是否含真实类：

```bash
jar tf tradplus-googlex-*.aar
# classes.jar 内应有 com/tradplus/ads/google/GoogleInitManager.class
```

没有 `GoogleInitManager` → 版本错了，不要继续改业务代码。

官方 demo 形态（**版本勿照抄，只抄结构**）：

```kotlin
implementation("com.google.android.gms:play-services-ads:{version}")
implementation("com.tradplusad:tradplus-googlex:2.{tpVersion}")
implementation("com.facebook.android:audience-network-sdk:{version}")
implementation("com.tradplusad:tradplus-facebook:1.{tpVersion}")
implementation("com.tradplusad:tradplus-pangle:19.{tpVersion}")
implementation("com.pangle.global:pag-sdk:{version}")
implementation("com.tradplusad:tradplus-unity:5.{tpVersion}")
implementation("com.unity3d.ads:unity-ads:{version}")
implementation("com.fyber:marketplace-sdk:{version}")
implementation("com.tradplusad:tradplus-fyber:24.{tpVersion}")
implementation("com.tradplusad:tradplus-mintegralx_overseas:18.{tpVersion}")
implementation("com.mbridge.msdk.oversea:mbridge_android_sdk:{version}")
implementation("com.tradplusad:tradplus-vunglex:7.{tpVersion}")
implementation("com.vungle:vungle-ads:{version}")
implementation("com.bigossp:bigo-ads:{version}")
implementation("com.tradplusad:tradplus-bigo:57.{tpVersion}")
implementation("com.tradplusad:tradplus-crosspromotion:27.{tpVersion}")
implementation("com.google.code.gson:gson:{version}")
implementation("com.tradplusad:tp_exchange:40.{tpVersion}")
```

TradPlus 常见仓库：`google()`、`mavenCentral()`、`https://jitpack.io`、Mintegral overseas、Pangle。

某个 `{tpVersion}` 的 adapter 在 Maven 上还没有时：把 **主包和所有 adapter 一起**降到已发布的那一档，不要主包 16.9、adapter 16.7 混用，更不要拿 `66.4.42` 冒充。

## 切走某平台时移除

| 切走 | 移除 |
|------|------|
| MAX | `com.applovin:applovin-sdk`、所有 `com.applovin.mediation:*` |
| TopOn | `com.thinkup.sdk:*`、宿主源码 `**/topon/custom/**` |
| AdMob | `play-services-ads` 及 `com.google.ads.mediation:*`（UMP 若仍要同意弹窗，评估是否保留 ads） |
| TradPlus | `com.tradplusad:*`、`tp_exchange`、`adapter-util`、`compare_price-release.aar`、各广告源 SDK（若无其它平台再用） |

多平台并存时不要误删仍被另一平台使用的广告源 SDK。

## BuildConfig 字段

按启用平台添加，未启用不加。写入宿主现有配置类，不要假设某个业务工程的路径。

## ProGuard（按仍启用的平台追加）

```proguard
-keep class {AdCallbackImp 完整类名} { *; }
-keep class {namespace}open.** { *; }

# MAX
-keep class com.applovin.** { *; }
-dontwarn com.applovin.**

# TopOn / ThinkUp
-keep class com.thinkup.** { *; }
-dontwarn com.thinkup.**

# TradPlus
-keep public class com.tradplus.** { *; }
-keep class com.tradplus.ads.** { *; }
-keep class com.tradplus.adapter.** { *; }
-dontwarn com.tradplus.**

# TradPlus 比价（正式包 Class.forName，漏 keep 必崩）
-keep class com.tp.compareprice.** { *; }
-dontwarn com.tp.compareprice.**
```

广告源（Meta / Pangle / Mintegral / GMS ads）keep 以各网络文档 + 打包脚本为准。

## adsdk 侧相关路径

| 路径 | 说明 |
|------|------|
| `adsdk/project.config` | `enable_platform` / `package_name` / `namespace` / 中介 |
| `adsdk/scripts/configure_project.py` | 打印宿主依赖与混淆 |
| `adsdk/ad/libs/compare_price-release.aar` | TradPlus 比价库 |
| `adsdk/ad/src/admob/` `max/` `topon/` `tradplus/` | 各平台实现，未 enable 的不会打进 AAR |
| `adsdk/aar-records/{代号}/` | 归档 AAR |
| `adsdk/README.markdown` | 通用 adSdk 说明（AdCallback / 埋点 / JSON） |
