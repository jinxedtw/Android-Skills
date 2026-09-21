# 固定测试凭证与本地 adConfig

运营正式 ID 未到之前，**MAX 一律用本节测试凭证**。不要再向用户要 MAX SDK Key、MAX 广告位 ID。

仍要问的只有：

1. 目标平台集合（以及旧平台删还是留）
2. 测试 + 正式 `applicationId`（正式包名只写入 adsdk `package_name`，不要改宿主 `AppConfig.APP_ID`）
3. adsdk `namespace`（一般等于宿主源码包名）
4. **Remote Config Key**（本地文件名固定 `adConfig.json`）
5. 中介清单（目标含 max / admob / tradplus 时）
6. TopOn / TradPlus 凭证（仅启用对应平台时）

## MAX 测试 SDK Key

`getMaxID()` / `BuildConfig.MAX_ID` 固定填：

```
PDvOTbswoo01eoxAP4gVN15Jf4oml0ITrtJXXJ9Ot1LHoeEbEWrQdhahmI0KKhecPghmVOnvXqMW3iAHnzWr_o
```

## MAX 测试广告位 ID

按 `format` 选用，**不要改 ID**。`adPlace` label 必须沿用宿主原广告位（如 `pdfCMngStart`），不要发明新名字。

| format | MAX 测试 unit id |
|--------|------------------|
| `open` | `870601c9d2bd4e20` |
| `int` | `a82d8c0a4462e2cd` |
| `nav` | `1f0cf5afa540f759` |
| `ban` | `d0c717531b4a1f6c` |

无激励位就不要造 `video` 行。若宿主本来就有激励位，向运营要正式 ID；测试阶段可暂不配。

## 生成本地 `adConfig.json`

1. 从宿主现有广告位收集 `label` + `format`（`AdManager.AdPlace` / 旧 `d0_config.json` 均可）。
2. 新建 **一份** `app/src/main/assets/adConfig.json`，结构为 `day0` ~ `day3`。写入 `app/.gitignore`，不要提交。
3. 每一天都写入全量广告位；测试阶段四天可以用同一套 MAX 测试 ID。
4. `platform` 写 `"max"`（不写时非 `ca-app-pub` 也会默认 MAX，显式写上更稳）。
5. `value` 可沿用旧配置权重；没有就开屏 10、插页 8~9、原生/Banner 2。
6. 宿主 `getLocalAdConfigFileName()` 固定 `"adConfig.json"`。
7. `getRemoteAdConfigKey()` **只问这一次**，填运营给的 key（例：`fetch_ad_all`）。线上 JSON 与本地同结构。
8. 旧的 `d0_config.json` / `adDay0` 分文件逻辑删掉或停用，避免和 adSdk 抢配置。

```json
{
  "day0": {
    "adArrays": [
      {
        "adPlace": "{原label，如 pdfCMngStart}",
        "openSwitch": true,
        "adInfos": [
          { "id": "870601c9d2bd4e20", "value": 10, "format": "open", "platform": "max" }
        ]
      }
    ]
  },
  "day1": {},
  "day2": {},
  "day3": {}
}
```

`day1`~`day3` 测试阶段复制 `day0` 即可。
