# 1. 開始編譯
Write-Host "--- Start Compiling Web ---" -ForegroundColor Cyan
flutter build web --release --base-href "/focus-stone/"

# 2. 將 build/web 複製回 git 追蹤的根目錄
Write-Host "--- Copying built files to repo root ---" -ForegroundColor Cyan
$src = "build\web"
$dst = "."
Get-ChildItem -Path $src | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $dst -Recurse -Force
}

# 3. Git 上傳
Write-Host "--- Uploading to GitHub ---" -ForegroundColor Yellow
git add -A
$commitMsg = "Update_Stone_" + (Get-Date -Format 'yyyyMMdd_HHmm')
git commit -m $commitMsg
git push -u origin main -f

Write-Host "--- Done! Check your iPhone in 1 min ---" -ForegroundColor Green