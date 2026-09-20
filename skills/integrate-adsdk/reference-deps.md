# TradPlus 宿主依赖参考

版本号会变。**优先使用 adsdk 打包结束时脚本打印的 dependencies / repositories。** 下文为形态参考

## dependencies 形态

```kotlin
dependencies {
    implementation(files("libs/adSdk-release.aar"))
    implementation(files("libs/compare_price-release.aar"))

    // TradPlus 主包
    implementation("com.tradplusad:tradplus:16.7.20.1")

    // AdMob
    implementation("com.google.android.gms:play-services-ads:25.4.0")
    implementation("com.tradplusad:tradplus-googlex:2.16.7.20.1")

    // Meta
    implementation("com.facebook.android:audience-network-sdk:6.22.0")
    implementation("com.tradplusad:tradplus-facebook:1.16.8.50.1")

    // Pangle
    implementation("com.tradplusad:tradplus-pangle:19.16.7.20.1")
    implementation("com.pangle.global:pag-sdk:8.1.0.5")

    // UnityAds
    implementation("com.tradplusad:tradplus-unity:5.16.7.20.1")
    implementation("com.unity3d.ads:unity-ads:4.19.0")

    // Fyber
    implementation("com.fyber:marketplace-sdk:8.4.7")
    implementation("com.tradplusad:tradplus-fyber:24.16.7.20.1")
    implementation("com.google.android.gms:play-services-ads-identifier:18.0.1")
    implementation("com.google.android.gms:play-services-base:18.1.0")

    // Mintegral
    implementation("com.tradplusad:tradplus-mintegralx_overseas:18.16.7.20.1")
    implementation("androidx.recyclerview:recyclerview:1.1.0")
    implementation("com.mbridge.msdk.oversea:mbridge_android_sdk:17.1.71")

    // Liftoff (Vungle)
    implementation("com.tradplusad:tradplus-vunglex:7.16.7.20.1")
    implementation("com.vungle:vungle-ads:7.7.7")

    // Bigo
    implementation("com.bigossp:bigo-ads:5.10.1")
    implementation("com.tradplusad:tradplus-bigo:57.16.7.20.1")

    // Cross Promotion / TP Exchange
    implementation("com.tradplusad:tradplus-crosspromotion:27.16.7.20.1")
    implementation("com.google.code.gson:gson:2.8.6")
    implementation("com.tradplusad:tp_exchange:40.16.7.20.1")
}
```

只加运营后台 **已开启** 的广告源，勿全量抄死。

## repositories 形态

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven(url = "https://jitpack.io")
        maven { url = uri("https://dl-maven-android.mintegral.com/repository/mbridge_android_sdk_oversea") }
        maven { url = uri("https://artifact.bytedance.com/repository/pangle") }
        // 其它中介仓库以打包脚本 / 运营文档为准
    }
}
```

## 需移除的旧依赖（仅 TradPlus 时）

- `com.applovin:applovin-sdk` 及所有 `com.applovin.mediation:*`
- `com.thinkup.sdk:*`（TopOn / ThinkUp）
- 宿主源码 `**/topon/custom/**`（Custom Max Bidding Adapter 等）

## BuildConfig

```kotlin
buildConfigField("String", "TRAD_PLUS_ID", "\"${aa.getProperty("tradPlusId")}\"")
```

## ProGuard（完整片段）

```proguard
-keep public class com.tradplus.** { *; }
-keep class com.tradplus.ads.** { *; }

-keep class com.tp.compareprice.** { *; }
-dontwarn com.tp.compareprice.**
```

## adsdk 侧相关路径

| 路径 | 说明 |
|------|------|
| `adsdk/project.config` | `enable_platform` / `package_name` / `namespace` |
| `adsdk/scripts/configure_project.py` | 打印宿主依赖与混淆 |
| `adsdk/ad/libs/compare_price-release.aar` | 比价库源文件 |
| `adsdk/ad/src/tradplus/` | TradPlus 平台实现 |
| `adsdk/aar-records/{代号}/` | 归档 AAR |
| `adsdk/README.markdown` | 通用 adSdk 说明 |
