---
name: jadx-apk-report
description: >-
  用 jadx 反编译 APK，并输出 Markdown 格式的 APK 分析报告（含详细 app 信息）。
  Use when the user invokes /jadx-apk-report or asks to 反编译 APK.
disable-model-invocation: true
---

# jadx 反编译 APK 并出报告

通过 jadx 工具完成对 apk 的反编译，输出 apk 的分析报告。

## jadx 与输出目录

- 在工程当前目录找 jadx；找不到再问
- 输出目录在当前目录新建文件夹

## 报告

输出格式为 markdown，包含详细的 app 信息。
