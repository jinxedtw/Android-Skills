# TradPlus 接入常见问题

## 1. 正式包崩溃：compare_price

```
IllegalStateException: 宿主未接入 compare_price-release.aar，
请添加: implementation(files("libs/compare_price-release.aar"))
```

### 原因

adsdk 在 TradPlus `init` 时会：

```kotlin
Class.forName("com.tp.compareprice.ComparePriceUtil")
```

| 场景 | 结果 |
|------|------|
| debug（通常未 minify） | 类名保留 → 正常 |
| release + R8 | 类被裁剪/改名 → `Class.forName` 失败 |

依赖写了 aar **不等于**正式包一定有该类。

### 处理

1. 确认 `implementation(files("libs/compare_price-release.aar"))`  
2. ProGuard 增加：

```proguard
-keep class com.tp.compareprice.** { *; }
-dontwarn com.tp.compareprice.**
```

3. 重打 **release** 验证。

---

## 2. 原生广告隔次失败

### 原因（平台）

TradPlus 文档：同一广告位是 **全局单例**。  
adsdk 若每次续缓存都 `new TPNative(sameUnitId)`，会冲掉前一个实例 → 轮播隔一次失败。Max/AdMob 无此限制，故换平台「看起来没问题」。

### 处理（adsdk）

`NavTradplusAdImp`：

- 按 `unitId` 复用同一个 `TPNative`
- `show` 前检查 `isReady()`
- 展示后在同一实例上 `loadAd()`，禁止再 `new`

### 处理（宿主）

循环 Banner（如 2 页 info|ad）在信息页会预绑定左右两个广告页：

- **不要**在 `bindData` 里 `showNavOrBan`
- **要**在广告页 `onPageSelected` 后再 show
- 容器/缓存未就绪可短重试；离开广告页取消任务

---

## 3. 有缓存但不展示 / platform 错误

TradPlus unit **必须**在 JSON 写：

```json
"platform": "tradplus"
```

SDK 不会根据 unitId 推断 TradPlus。

---

## 4. 运行时包名校验失败

adsdk `project.config`：

```properties
package_name = com.test.app,{正式applicationId}
```

白名单不含正式包名 → 校验失败。改白名单后需 **重打 AAR**。

---