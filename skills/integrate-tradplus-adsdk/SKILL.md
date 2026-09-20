---
name: integrate-tradplus-adsdk
description: >-
  将宿主 Android 工程从 Max/TopOn（或其它聚合）切换/接入 TradPlus，并正确接入
  adSdk-release.aar + compare_price-release.aar。覆盖打包 SDK、替换 AAR、
  Gradle 依赖与仓库、AdCallback、adConfig.json、ProGuard、正式包崩溃与
  原生广告单例。Use for 接入 TradPlus、切换广告聚合、compare_price、
  adSdk AAR、tradplusAppId、platform tradplus、ComparePriceUtil、
  TPNative 全局单例、enable_platform=tradplus。
disable-model-invocation: false
---

# 宿主接入 TradPlus（adSdk）

把已用 **adSdk** 的 Android 宿主切到 **TradPlus**。广告能力走 `AdCallbackImp`，不直接调各网络 SDK。

详细依赖坐标、仓库、ProGuard 全文见 [reference-deps.md](reference-deps.md)。  
已知崩溃与原生单例见 [reference-pitfalls.md](reference-pitfalls.md)。

```
任务进度：
- [ ] 已确认运营：TradPlus App ID、广告位 ID、中介清单、Remote Config Key
- [ ] adsdk 已按 enable_platform=tradplus 打出 AAR + compare_price
- [ ] 宿主 libs 已替换 adSdk-release.aar，并放入 compare_price-release.aar
- [ ] 已移除 Max/TopOn 宿主依赖与自定义 Adapter（若不再使用）
- [ ] 已添加 TradPlus 主包 + 中介 Adapter + Maven 仓库
- [ ] AdCallbackImp 已实现 getTradplusAppId；max/topon 返回空串
- [ ] assets adConfig.json 广告位均带 "platform": "tradplus"
- [ ] Manifest meta-data 与 namespace 一致
- [ ] ProGuard 已 keep tradplus + compare_price
- [ ] debug / release 均能初始化且无 ClassNotFoundException
```

## 0. 先收集，再改代码

**信息不齐时不要改依赖、不要换 AAR。**

| 收集项 | 用途 | 校验                                      |
|--------|------|-----------------------------------------|
| **TradPlus App ID** | `getTradplusAppId()` / `BuildConfig.TRAD_PLUS_ID` | 非空                                      |
| **广告位 ID 列表** | `adConfig.json` 的 `adInfos[].id` | 覆盖开屏/插页/原生等                             |
| **中介清单** | 宿主 Adapter | 与运营后台一致                                 |
| **Remote Config Key** | `getRemoteAdConfigKey()` | 与线上一致                                   |
| **宿主包名** | adsdk `project.config` → `package_name` | 必须含正式 `applicationId`和测试的`applicationId` |
| **adsdk namespace** | 公开 API = `{namespace}open` | 与 Manifest `android:value` 一致           |

向运营确认：是否 **只接 TradPlus**（可删 Max/TopOn）。

## 1. 打包 TradPlus 专用 adSdk AAR

在 **adsdk** 工程执行，不是宿主。

```properties
project_code = {代号}
package_name = {测试包名},{正式包名}
namespace = {宿主包名前缀}     # 例 com.ai.smart → API 包 com.ai.smartopen
enable_platform = tradplus     # 仅 TP 时不要带 max/topon
```
用这个配置替换**adsdk**工程里面的[project.config](../../../adsdk/project.config)，然后执行命令

```bash
sh configure_project.sh
```
输入0后开始打包

| 产物                                                                                                                                                     | 说明 |
|--------------------------------------------------------------------------------------------------------------------------------------------------------|------|
| `aar-records/{代号}/`                                                                                                                                    | 归档 AAR + mapping + config |

**硬规则：** TradPlus 在 AAR 内为 `compileOnly`；运行时依赖由宿主提供。漏接 `compare_price` → 初始化即崩。

## 2. 宿主替换 AAR

```
app/libs/
├── adSdk-release.aar           # 覆盖为 TradPlus 版
└── compare_price-release.aar   # 从 adsdk/ad/libs/ 拷入（必接）
```

```kotlin
implementation(files("libs/adSdk-release.aar"))
implementation(files("libs/compare_price-release.aar"))
```

公开 API 包名必须与 AAR 一致；换 namespace 重打后，宿主 import / Manifest 同步改。

## 3. Gradle：删旧聚合，加 TradPlus

**移除（仅 TradPlus 时）：** MAX SDK + adapters、TopOn/`com.thinkup.sdk:*`、项目内 `**/topon/custom/**`。

**增加：** TradPlus 主包 + 运营开启的中介 Adapter + 对应 Maven 仓库。坐标与仓库全文见 [reference-deps.md](reference-deps.md)。**优先以 adsdk 打包脚本打印为准。**

```kotlin
defaultConfig {
    buildConfigField("String", "TRAD_PLUS_ID",  "\"${AppConfig.Key.TRAD_PLUS_ID}\"")
}
```

宿主的[AppConfig.kt](../../../pdf06/buildSrc/src/main/kotlin/com/assemble/config/AppConfig.kt) 增加 `tradPlusId=`。

## 4. AdCallbackImp

打出来的aar会根据项目不同加不同的前缀进行混淆

```kotlin
override fun getTradplusAppId(): String = BuildConfig.TRAD_PLUS_ID
```

- 删除对旧 Max/AdMob 比价 jar 的 `askAdmobEcpm`；TradPlus 走 `compare_price`。
- 去掉 `canForceCloseApplovinAd` 等 Max 专用逻辑。
- `SllzNativeAdStyle` 参数以 **当前 AAR API** 为准。

Manifest：

```xml
<meta-data
    android:name="{完整类名.AdCallbackImp}"
    android:value="{namespace}" />
```

`android:value` = 打包时 `project.config` 的 `namespace`。若与 AdMob/TP 合并冲突，可加 `tools:replace="android:networkSecurityConfig"`。

## 5. 广告配置 JSON
需要包含测试的广告配置和正式的广告配置

每个 TradPlus unit **必须**写 platform：

```json
{ "id": "{unit-id}", "value": 50, "format": "nav", "platform": "tradplus" }
```

| format | 含义 |
|--------|------|
| `open` / `int` / `nav` / `ban` / `video` | 开屏 / 插页 / 原生 / Banner / 激励 |

SDK **不会**按 unitId 推断 TradPlus；漏写 platform → 无填充。

## 6. ProGuard + 坑

正式包必须 keep `com.tradplus.**` 与 `com.tp.compareprice.**`。规则与崩溃说明见 [reference-pitfalls.md](reference-pitfalls.md)。

原生：TradPlus 同广告位全局单例；adsdk 须复用 `TPNative`；宿主轮播建议 **选中页再 show**。

## 7. 验收

| 场景 | 期望 |
|------|------|
| debug / release 冷启 | 不崩（尤其 compare_price） |
| 开屏 / 插页 | 有填充与展示 |
| 首页原生轮播 | 连续可展示，无隔次空壳 |
| 换包名 | `package_name` 白名单已含并重打 AAR |

## 8. Agent 约束

1. 不要只换 AAR 不改依赖。  
2. 不要漏拷 `compare_price-release.aar`。  
3. 不要省略正式包 `com.tp.compareprice.**` keep。  
4. 不要在 `adConfig` 省略 `"platform": "tradplus"`。  
5. 不要漏把正式包名写入 `package_name` 白名单。  
6. 中介版本以运营与 **打包脚本打印**为准。  
7. 改 adsdk 后必须 clean 重打 AAR，确认仍有 `{namespace}open` 公开 API。
