# Android-Skills

**只存放 Cursor / AI Agent 用的 Skill 文档**，不放工程源码、AAR、密钥或业务项目。

```
Android-Skills/
├── README.md
└── skills/
    └── <skill-name>/
        ├── SKILL.md           # 必选：入口（YAML frontmatter + 主流程）
        └── reference-*.md     # 可选：细节、依赖、踩坑（渐进披露）
```

## 当前 Skills

| 目录 | 用途 |
|------|------|
| [skills/integrate-tradplus-adsdk](skills/integrate-adsdk/SKILL.md) | 宿主 Android 工程接入 / 切换 TradPlus（adSdk + compare_price） |

## 新增 Skill

```bash
mkdir -p skills/<skill-name>
# 编写 skills/<skill-name>/SKILL.md
# 细节多时再拆 reference-*.md，并在 SKILL.md 里链接过去
git add skills/<skill-name>
git commit -m "docs: add <skill-name> skill"
git push
```