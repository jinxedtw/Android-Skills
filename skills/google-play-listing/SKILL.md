---
name: google-play-listing
description: >-
  Prepare an Android app for Google Play listing: ask for a materials directory,
  audit code for gaps and policy risks, write an English store description to
  商店页介绍.txt (max 4000 characters), and capture real-device screenshots into
  play_screenshots/ and google_play/ (max 8). Use when the user says Google Play
  listing, Play Store publish, 上架, 商店页, play_screenshots, or /google-play-listing.
disable-model-invocation: true
---

# Google Play Listing

帮助用户完成 Google Play 上架物料与合规检查。先问目录，再检查、写介绍、截图。

## 何时使用

用户提到或输入：

- `/google-play-listing`
- Google Play listing / Play Store publish
- 上架 / 商店页 / play_screenshots

## 必须先做：询问物料目录

向用户询问一个存放物料的目录。未得到明确路径前，不要写 `商店页介绍.txt`，也不要落盘截图。

确认后，在该目录下使用：

```text
<物料目录>/
  商店页介绍.txt
  play_screenshots/          # 全部真机截图
  play_screenshots/google_play/  # 最多 8 张上线图
```

## 工作流程

按顺序执行；任一步被阻塞（无真机、权限失败、缺隐私链接等）先问用户，不要假装完成。

### 1. 检查代码有无缺漏，有没有上架违规的风险点

对照仓库做只读审计，输出风险清单（高/中/低 + 文件位置 + 建议）。至少覆盖：

- Manifest：权限是否最小必要；`exported`、Intent Filter、Deep Link、FileProvider
- 隐私政策 / 服务条款 URL 是否可访问、非占位、与应用内入口一致
- 签名：`keystore` / 密码 / `google-services.json` 是否误用占位或误提交密钥
- 广告 / 追踪：残留广告布局、未用 SDK、Data safety 相关采集是否说清
- 目标与兼容：`targetSdk`、Android 15 行为（通知、前台服务、分区存储）
- Kotlin `removeFirst()` / `removeLast()`：与 Android 15 Java API 冲突，低版本会崩；改为 `removeAt(0)` / `removeAt(list.lastIndex)`
- 稳定性：明显 crash 路径、TODO/占位实现、release 是否开启 Crashlytics mapping 上传
- ProGuard/R8：发布必要 keep；勿依赖已删除的广告规则残留
- 商店素材依赖：图标、feature graphic、应用名是否齐全（缺则列出，不擅自造假合规证明）

更细的检查表见 [reference.md](reference.md)。

### 2. 生成商店页介绍（英文）

要求（按用户原意执行）：

- 帮我生成商店页介绍，不能多于4000字，尽量解决4000字，以商店页介绍.txt的文件保存在目录，这个目录需要询问
- 本 skill 约定：正文为英文；「4000字」按 Google Play full description 的 **4000 characters** 限制执行，尽量接近但不得超过 4000
- 文件名固定：`商店页介绍.txt`（UTF-8）
- 内容基于真实功能与审计结果，禁止虚构未实现能力；可含功能要点、适用场景、权限说明摘要、支持与更新说明
- 写完后统计字符数并告诉用户；超限必须删减后再保存

### 3. 真机截图 → 商店上线图

要求（按用户原意执行）：

- 生成app内截图用户当成商店上线图，截图放在物料目录的play_screenshots文件夹下，同时生成一个子目录google_play里面放最多8张上线图，选取你认为最有价值的截图，用真机进行截图，如果没有连上真机或者遇到权限问题找我询问

执行细则：

1. 先 `adb devices`：无 device / unauthorized / 权限问题 → **立刻问用户**，不要改用模拟器冒充「真机上线图」除非用户明确同意
2. 安装当前要上架的构建（优先 release/正式包；用户指定则从其指定）
3. 用真机走核心路径截图；可用本 skill 脚本：
   - Windows: `scripts/capture_play_screenshots.ps1`
   - Unix: `scripts/capture_play_screenshots.sh`
4. 全部原图放入 `<物料目录>/play_screenshots/`
5. 自选最多 **8** 张最有价值的图复制到 `<物料目录>/play_screenshots/google_play/`，命名建议 `01_....png` … `08_....png`
6. 优先选取：首页扫描、结果页、生成/历史、设置或权限相关、能体现核心卖点的界面；避免大片空白、调试浮层、个人隐私信息

截图价值不够或流程走不通时，说明缺什么并问用户。

### 4. 上架过程补充（参照 qrScanner 类应用经验）

在 1–3 之外，主动核对并回报：

- Feature graphic / 高清图标是否就绪（没有则提醒用户准备，不在此强制生成违规素材）
- Short description（≤80 characters）是否需要一并起草（默认写在回复里，除非用户要求另存文件）
- What’s new / 版本说明是否需要多语言草稿（用户要时再写）
- Data safety、权限申报与应用内实际行为是否一致
- 正式包是否已用正确签名与 Firebase/Google 配置（非 placeholder）
- 若存在广告：测试设备、子账户、隐私披露是否齐全

## 输出格式

完成后简要回报：

1. 物料目录路径
2. 合规风险清单（若有阻断项标为必须先修）
3. `商店页介绍.txt` 路径与英文 character 数
4. `play_screenshots/` 与 `google_play/` 数量；若未截图写明原因（并已询问用户）
5. 建议的下一步（修风险 / 上传 Play Console / 补 graphic）

## 脚本

- [scripts/capture_play_screenshots.ps1](scripts/capture_play_screenshots.ps1)
- [scripts/capture_play_screenshots.sh](scripts/capture_play_screenshots.sh)

用法见脚本头部注释。截图文件名由调用方/Agent 在每次 `exec` 时传入。
