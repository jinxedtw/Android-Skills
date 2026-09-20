# android-ad-skills

**只存放 Cursor / AI Agent 用的 Skill 文档**，不放工程源码、AAR、密钥或业务项目。

目录约定对齐 [flutter-skills](https://github.com/hzl000/flutter-skills)：

```
android-ad-skills/
├── README.md
└── skills/
    └── <skill-name>/
        ├── SKILL.md           # 必选：入口（YAML frontmatter + 主流程）
        └── reference-*.md     # 可选：细节、依赖、踩坑（渐进披露）
```

## 当前 Skills

| 目录 | 用途 |
|------|------|
| [skills/integrate-tradplus-adsdk](skills/integrate-tradplus-adsdk/SKILL.md) | 宿主 Android 工程接入 / 切换 TradPlus（adSdk + compare_price） |

## 新增 Skill

```bash
mkdir -p skills/<skill-name>
# 编写 skills/<skill-name>/SKILL.md
# 细节多时再拆 reference-*.md，并在 SKILL.md 里链接过去
git add skills/<skill-name>
git commit -m "docs: add <skill-name> skill"
git push
```

规则：

- `name`：小写 + 连字符，与文件夹名一致  
- `description`：写清 WHAT + WHEN（触发词），便于 Agent 发现  
- 主文件尽量精炼；版本号、长依赖列表放 `reference-*.md`  
- **禁止**提交：工程代码、`*.aar` / `*.jks` / 密钥、`.env`、构建产物  

## 在工程里使用

```bash
# 软链到具体项目（推荐，方便随本仓库更新）
ln -sfn /path/to/android-ad-skills/skills/integrate-tradplus-adsdk \
        /path/to/your-app/.cursor/skills/integrate-tradplus-adsdk
```

或对话里直接 `@skills/integrate-tradplus-adsdk/SKILL.md`。
