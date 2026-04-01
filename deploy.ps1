# 0. 更新 version.json
$version = Get-Date -Format "yyyyMMddHHmmss"
"{`"v`":`"$version`"}" | Set-Content -Path "web\version.json" -Encoding UTF8
Write-Host "--- Version: $version ---" -ForegroundColor Magenta

# 1. 編譯
Write-Host "--- Start Compiling Web ---" -ForegroundColor Cyan
flutter build web --release --base-href "/focus-stone/"
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed!" -ForegroundColor Red; exit 1 }

# 2. 複製 build/web 到根目錄
Write-Host "--- Copying built files to repo root ---" -ForegroundColor Cyan
Get-ChildItem -Path "build\web" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination "." -Recurse -Force
}

# 3. Git commit
Write-Host "--- Uploading to GitHub ---" -ForegroundColor Yellow
git add -A
git commit -m "Deploy_$version"
if ($LASTEXITCODE -ne 0) { Write-Host "Nothing to commit." -ForegroundColor DarkGray }

# 4. Push main（最多重試 3 次）
$pushed = $false
for ($i = 1; $i -le 3; $i++) {
    git push origin main 2>&1
    if ($LASTEXITCODE -eq 0) { $pushed = $true; break }
    Write-Host "Push attempt $i failed, retrying..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}
if (-not $pushed) {
    Write-Host "Push failed after 3 attempts!" -ForegroundColor Red
    exit 1
}

# 5. 打 tag（保留最近 5 個）
git tag "v$version" 2>&1
git push origin "v$version" 2>&1

$allTags = git tag --sort=-creatordate | Where-Object { $_ -match "^\d{14}$" -or $_ -match "^v\d{14}$" }
if ($allTags.Count -gt 5) {
    $oldTags = $allTags | Select-Object -Skip 5
    foreach ($old in $oldTags) {
        git tag -d $old | Out-Null
        git push origin --delete $old 2>&1 | Out-Null
    }
}

Write-Host "--- Done! Version: $version ---" -ForegroundColor Green
Write-Host "  To rollback, run: .\rollback.ps1" -ForegroundColor DarkCyan
