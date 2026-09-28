---
name: create-synced-skill
description: >-
  按 Cursor Agent Skill 规范新建或更新一个 skill，提交并推送到
  https://github.com/jinxedtw/Android-Skills 的 skills/ 目录，再在本机
  ~/.cursor/skills 挂直接链接。Use when the user invokes /create-synced-skill
  or asks to create a skill and sync it to the Android-Skills GitHub repository.
disable-model-invocation: true
---

# 创建并同步 Skill

把 skill 写进 `~/src/Android-Skills`（`origin` = `https://github.com/jinxedtw/Android-Skills.git`），推到 `main` 的 `skills/<name>/`。

## 先问清

信息不全就先问，不要先写文件：

1. 要完成的具体任务
2. 何时使用（触发词）
3. Agent 原本不知道、必须写进文档的领域知识
4. 输出格式，或必须原样保留的句子
5. 要不要 `scripts/`，或单独的 reference 文件

用户给出的必须原文，按原词原序写入。不要改写、不要扩写，也不要在原文外再加标题。

## 写成什么样

- 目录名等于 frontmatter `name`：小写字母、数字、连字符，最长 64
- `description`：第三人称，写清做什么、何时用，最长 1024，带上触发词
- 默认 `disable-model-invocation: true`。只有用户明确要求「相关时自动使用」才去掉这一行
- 只写 Agent 不知道的步骤。`SKILL.md` 少于 500 行
- 长文档放同级 `reference.md`，从 `SKILL.md` 单层链接
- 不要写到 `~/.cursor/skills-cursor/`

## 落盘

仓库不在时先克隆：

```bash
mkdir -p ~/src
git clone https://github.com/jinxedtw/Android-Skills.git ~/src/Android-Skills
```

文件写到：

```text
~/src/Android-Skills/skills/<name>/SKILL.md
```

已有同名目录时就地更新，不要再套一层目录。

本机要让 Cursor 扫到。链接必须是 `~/.cursor/skills` 的直接子目录，不要包在别的文件夹里，也不要让链接指向自己：

```bash
mkdir -p ~/.cursor/skills
ln -sfn ~/src/Android-Skills/skills/<name> ~/.cursor/skills/<name>
```

若会话上下文里有 user Agent Store，把同一份 `SKILL.md` 再写到该 store 的 `skills/<name>/SKILL.md`。Store 没挂载就跳过，并说明这份只在本机 `~/.cursor/skills`。

## 推送

在 `~/src/Android-Skills`：

1. 看 `git status`、`git diff`、`git log -5 --oneline`
2. 只 `git add skills/<name>`
3. 不要改 git config，不要 `--no-verify`，不要 force push
4. 不要提交密钥、`.env`、AAR
5. 用 HEREDOC 提交，说明为什么新增或更新这个 skill
6. `git push origin HEAD`
7. 再跑 `git status`，确认已经推上去

推送失败就停，把错误给用户，不要改远程历史。

## 做完告诉用户

- 仓库里的路径 `skills/<name>/`
- 本机链接 `~/.cursor/skills/<name>`
- 新开一个 Agent 对话，输入 `/<name>` 才会出现
