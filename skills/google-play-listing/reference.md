# Google Play listing — compliance checklist

Agent 执行「代码缺漏 / 上架违规风险」检查时按本节逐项过。发现项写入回报，标注 高/中/低。

## Privacy & policy

- [ ] Privacy policy URL opens in browser, not editor-only / placeholder / 404
- [ ] Terms of use URL same standard
- [ ] In-app links match store listing URLs
- [ ] Data safety answers match actual SDK behavior (Ads, Analytics, Crashlytics, etc.)

## App identity & signing

- [ ] ApplicationId / package name stable for the listing
- [ ] Release signing config present; passwords not committed in plain text to public remotes if avoidable
- [ ] `google-services.json` / Firebase config is the real project, not a sample placeholder
- [ ] Version code / version name bumped for the upload

## Manifest & permissions

- [ ] Only required permissions; sensitive ones have in-app justification / runtime request UX
- [ ] CAMERA / LOCATION / STORAGE / NOTIFICATIONS usage is explainable
- [ ] No unexpected `exported="true"` components without permission guards
- [ ] FileProvider paths are narrow

## Android 14/15 pitfalls

- [ ] No Kotlin `MutableList.removeFirst()` / `removeLast()` left in app code (crash on older devices when Java 15+ methods resolve first) — use `removeAt(0)` / `removeAt(lastIndex)`
- [ ] Foreground service types declared if used
- [ ] Notification permission flow on Android 13+
- [ ] Photo picker / media permissions aligned with targetSdk

## Monetization & leftover clutter

- [ ] Removed ad layouts / test ad units / dead mediation if product has no ads
- [ ] If ads exist: App-ads.txt / ad SDK init / child-directed flags reviewed
- [ ] No debug-only drawers or leak URLs in release

## Stability & release tooling

- [ ] ProGuard/R8 rules cleaned for current SDKs
- [ ] Crashlytics (or equivalent) mapping upload enabled for release
- [ ] Obvious crash paths (ClassCast, NPE on empty lists, missing permission) checked on main flows
- [ ] QS tiles / shortcuts / deep links do not crash when cold-started

## Store assets (beyond this skill’s auto files)

- [ ] Hi-res icon 512×512
- [ ] Feature graphic 1024×500
- [ ] Phone screenshots: 2–8 images (this skill fills up to 8 under `google_play/`)
- [ ] Short description ≤ 80 characters
- [ ] Full description ≤ 4000 characters (this skill’s `商店页介绍.txt`)

## Screenshot capture notes

- Prefer a physical device via `adb devices` status `device`
- Hide developer overlays / notch cutout debug / demo accounts PII
- Capture light path the store user will understand without narration
- `google_play/` must contain **at most 8** images
