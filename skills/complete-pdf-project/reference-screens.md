# 底板页面 ↔ Figma

默认底板 **PDF16**。对照时用「职责」对齐 Figma。类名保持可读（可轻度改名），路径按 [reference-diff.md](reference-diff.md) 打散。

用户选了别的 PDF 工程时，先按那个工程的页面列清单。

## 主路径

| 底板 | 典型职责 | Figma 常见帧 |
|------|----------|--------------|
| `SplashActivity` | 冷/热启动、进度条、开屏广告 | Splash / Loading |
| `OutOpenActivity` | 通知/小组件拉起 | 可无独立设计，逻辑必须留 |
| `ScanningActivity` | 首次扫描动画 | Scanning |
| `PermissionGuideActivity` / `PermissionWindowActivity` | 全文件 / 通知权限 | Permission |
| `MainActivity` | 首页容器、FAB、广告位 | Home |
| `HomeFileFragment` | 首页文件列表 | Home files |
| `ToolFragment` | 工具 Tab | Tools |
| `SearchActivity` | 搜索 | Search |
| `AllFilesActivity` / `FileListFragment` | 全部文件 | All files |

## 功能

| 底板 | 典型职责 |
|------|----------|
| `FunctionActivity` | 编辑 / 签名 / 文字 / 打印 / Word 转 PDF 的文件选择 |
| `Image2PdfActivity` / `AllPhotoActivity` | 图转 PDF |
| `IdCardTypeActivity` / `IdCardAddActivity` | 证件扫描 |
| `PdfViewActivity` / `DocViewActivity` | 阅读与编辑 |
| `FileActionActivity` / `FileOldActivity` | 文件操作、旧文件 |
| `FinishActivity` / `FinishAnimActivity` / `FinishCompleteActivity` | 完成后页（常带插页） |
| `SettingActivity` / `LanguageActivity` | 设置、语言 |
| `UninstallRetentionActivity` / `UninstallFeedbackActivity` | 卸载挽留 |

Popup（`view/popup`）、通知布局、Widget、原生广告布局（`layout_nav_*`）一并对照 Figma；广告容器 id 不要删。

## 主题色

PDF16 主色是 `colors.xml` 的 `main`。换肤先改 `main` 和 Figma 色板，再改写死在 Kotlin 里的 `ForegroundColorSpan(0xFF…)`（权限页、设默认阅读器弹窗等）。

## 换 layout 时

- 保留 `binding.xxx` 用到的 id；要删控件先搜 Kotlin。
- `showAd` / `loadAd` / `AdPlace` 调用留在原生命周期节点。
- 列表 Adapter 只改 item 布局，分页和点击原样。
