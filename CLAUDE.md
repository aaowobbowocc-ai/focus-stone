# 讀書石頭 (FocusStone) — 持久視覺與開發規範

## ⚠️ 每次執行指令前必讀

---

## 1. 核心視覺風格：日式治癒系 (Iyashikei / Tabi Kaeru) 繪本畫風

**所有** UI 設計、圖片生成、資產建議，必須嚴格遵守日式「治癒系 (Iyashikei)」繪本插畫風格。

### 強制視覺屬性

| 屬性 | 規定 |
|------|------|
| **材質** | 純水彩 (Watercolor) 渲染 + 色鉛筆 (Colored pencil) 質感，必須像手繪在紙上 |
| **線條** | 柔和鉛筆線條 (Soft pencil outlines)。**禁止**僵硬黑色粗線、幾何形狀、向量圖形 |
| **色調** | 低飽和度、柔和粉彩色調。使用苔蘚綠、木頭棕、米白色、柔和藍。**禁止**鮮豔/螢光/高對比色 |
| **紋理** | 可見紙張紋理 (Visible paper grain)，增加手作感與懷舊感 |
| **氛圍** | 溫馨 (Cozy)、懷舊 (Nostalgic)、治癒 (Healing)、平靜 (Peaceful)、輕柔 (Gentle) |

### 圖片生成 Prompt 框架

每次生成圖片時套用：
```
[Subject] in a nostalgic Japanese watercolor healing book style, soft colored pencil texture,
muted natural earth tones, visible paper grain texture, gentle diffused lighting, cozy Tabi Kaeru vibe.
```

---

## 2. UI 實作原則

- **元件造型**：避免標準圓角矩形與現代發光特效。使用柔和、有機、手繪感的形狀，像從繪本裡剪出來的
- **動畫**：必須柔和、緩慢、不侵入（慢慢浮現、輕柔呼吸感）
- **顏色**：主色 `#7B4F2E`（木頭棕）、背景 `#F5E6C8`（米白）、強調 `#EDD9A3`（淡黃）

---

## 3. 技術規範

- **平台**：Flutter Web，部署到 GitHub Pages
- **base-href**：`/focus-stone/`
- **建置指令**：必須用 PowerShell 執行 `flutter build web --release --base-href '/focus-stone/'`（bash 會造成路徑錯誤）
- **部署**：執行 `.\deploy.ps1`，會自動更新版本號、build、複製、git push、打版本 tag
- **回復**：執行 `.\rollback.ps1`，列出最近 5 版供選擇，確認後自動 push 回復版本

---

## 4. 專案結構

```
pet_rock/          ← Flutter 專案（GitHub Pages repo）
  lib/
    home_page.dart
    firebase_service.dart
    stone_avatar.dart  ← CustomPainter 繪製石頭（0-9 種）
    shop_page.dart
    friends_page.dart
    history_page.dart
    changelog_page.dart
    ai_backend_service.dart
  web/
    index.html
    changelog.json ← 更新日誌（每次部署手動更新）
    version.json   ← iOS PWA 版本偵測（deploy.ps1 自動更新）
backend/           ← FastAPI AI 後端
  main.py
  ai_service.py   ← 改編自 ai_orchestrator.py（LiteLLM 多模型）
  cache.py        ← TTL 快取（6 小時）
```
