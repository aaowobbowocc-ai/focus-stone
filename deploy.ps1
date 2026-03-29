# 1. 開始編譯
Write-Host "--- Start Compiling Web ---" -ForegroundColor Cyan
flutter build web --release --base-href "/focus-stone/"

# 2. 進入資料夾
Set-Location build/web

# 3. 處理 Git 上傳 (簡化訊息避免報錯)
Write-Host "--- Uploading to GitHub ---" -ForegroundColor Yellow
git add .
# 我們把時間訊息簡化，避免空格導致 Git 誤判
$commitMsg = "Update_Stone_" + (Get-Date -Format 'yyyyMMdd_HHmm')
git commit -m $commitMsg
git push -u origin main -f

# 4. 回到根目錄
Set-Location ../..

Write-Host "--- Done! Check your iPhone in 1 min ---" -ForegroundColor Green