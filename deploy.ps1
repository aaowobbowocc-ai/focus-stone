# 0. 更新 version.json（讓 iOS PWA 偵測到新版本並自動重新載入）
$version = Get-Date -Format "yyyyMMddHHmmss"
"{`"v`":`"$version`"}" | Set-Content -Path "web\version.json" -Encoding UTF8
Write-Host "--- Version: $version ---" -ForegroundColor Magenta

# 1. 開始編譯
Write-Host "--- Start Compiling Web ---" -ForegroundColor Cyan
flutter build web --release --base-href "/focus-stone/"
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed!" -ForegroundColor Red; exit 1 }

# 2. 將 build/web 複製回 git 追蹤的根目錄
Write-Host "--- Copying built files to repo root ---" -ForegroundColor Cyan
$src = "build\web"
$dst = "."
Get-ChildItem -Path $src | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $dst -Recurse -Force
}

# 3. Git commit
Write-Host "--- Uploading to GitHub ---" -ForegroundColor Yellow
git add -A
$commitMsg = "Deploy_$version"
git commit -m $commitMsg

# 4. 打版本 tag（保留最近 5 個，舊的自動刪除）
$tagName = "v$version"
git tag $tagName
Write-Host "--- Tagged: $tagName ---" -ForegroundColor Magenta

$allTags = git tag --sort=-creatordate | Where-Object { $_ -match "^v\d{14}$" }
if ($allTags.Count -gt 5) {
    $oldTags = $allTags | Select-Object -Skip 5
    foreach ($old in $oldTags) {
        git tag -d $old | Out-Null
        Write-Host "  Removed old tag: $old" -ForegroundColor DarkGray
    }
}

# 5. Push（含 tags）
git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "Push failed! Retrying..." -ForegroundColor Red
    git push origin main --force
}
git push origin --tags --force

Write-Host "--- Done! Version: $version ---" -ForegroundColor Green
Write-Host "  To rollback, run: .\rollback.ps1" -ForegroundColor DarkCyan
