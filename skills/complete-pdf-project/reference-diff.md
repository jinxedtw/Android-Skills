# 与底板做差异化

`applicationId` 仍是 `com.test.app`。重点差异化 **目录路径（打散）**。类名、方法名只要不完全照抄底板即可，**必须保留可读性**。

## 不合格（禁止交付）

- 只把 `com.oowa.pdf` 换成新前缀，下面仍是 `view/page/splash/SplashActivity`（路径没打散）
- 类名加数字/New：`MainActivity2`、`SplashActivityNew`
- 类名改成看不懂的黑话：`DawnGate`、`NexusBoard`、`InkApp`
- 方法名全量改成看不懂的：`leaveViaSlot`、`spinBar`、`primeSlots`
- 所有类仍挤在和底板一一对应的文件夹里

## 路径（要彻底）

1. `NAME_SPACE` 换成与底板不同的新值（不要用 `com.oowa.pdf` / `com.cell.document` 等已知底板）。
2. 包目录 **重新切分**，不要复制 `view/page`、`view/popup`、`ad/imp`、`manage/scan` 这棵树。
3. **打散：** 底板同一目录下的类，拆到至少两个以上新包。启动页、权限页、首页不要再挂在同一个 `splash` / `main` 包下。
4. `buildSrc` 的 `com.assemble.config` 也可以换包名，但 gradle 引用要一起改。

## 类名（轻度、可读）

不要全量匿名化。优先：

- 保留职责词：`Splash`、`Main`、`File`、`Setting`、`Ad`
- 可以加/换一个前缀或同义词：`SplashActivity` → `LaunchSplashActivity`，`AdManager` → `AppAdManager`
- 文件名与类名一致

不要：

- `MainActivity` 原样再放回 `.../main/MainActivity`（路径已变才算差异化）
- `DawnGate` / `NexusBoard` 这类必须对照映射表才能看懂的名字

`AndroidManifest`、`tools:context`、Intent、Fragment 类名，跟最终类名走。

## 方法名（尽量不改）

`loadAd`、`goWithAd`、`goWithNormal`、`initAnim`、`showAd`、`funAction`、`clickFullScreenAd`、`fullAdInShowing` **默认保留**。

只在和底板完全同名且几乎无语义时才改，新名仍要一眼能懂。

**不要改：**

- Android / AndroidX override：`onCreate`、`onResume`、`onBindViewHolder`、`inflate` 等
- 第三方 SDK 与 adSdk 公开 API
- 资源 `R` 字段本身

## 资源文件

- layout 可以换名，但保持可读：`activity_splash.xml` → `activity_launch_splash.xml`，不要 `pane_dawn.xml`
- xml 里的 `@+id/`：被 Kotlin 用到的可以改，xml 和代码必须一起改；广告容器不要删
- `colors.xml` 的 `main` 可以留作主题入口，取值按 Figma

## 流程

1. 先打散路径、改 `NAME_SPACE`。
2. 类名只做轻度可读改名；方法名默认不动。
3. 再换 Figma UI、再接 adSdk（namespace 用新 `NAME_SPACE`）。

## 和广告 skill 的衔接

`clickFullScreenAd` / `fullAdInShowing` / `clickOpenMaxAd` **建议保留原名**，语义接到 `AdCallback`。不要因为改名把热启动 / 强制关页逻辑删掉。
