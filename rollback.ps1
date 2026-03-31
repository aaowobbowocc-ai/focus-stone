# rollback.ps1 — 回復到前幾版
# 使用方式：在 pet_rock 資料夾執行 .\rollback.ps1

# 列出最近 5 個版本 tag
$tags = git tag --sort=-creatordate | Where-Object { $_ -match "^v\d{14}$" } | Select-Object -First 5

if ($tags.Count -eq 0) {
    Write-Host "找不到任何版本 tag，請先用 deploy.ps1 部署一次。" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== 可回復的版本 ===" -ForegroundColor Cyan
for ($i = 0; $i -lt $tags.Count; $i++) {
    $t = $tags[$i]
    # 從 tag 名稱解析日期
    $raw = $t -replace "^v", ""
    $dt = [datetime]::ParseExact($raw, "yyyyMMddHHmmss", $null)
    $label = if ($i -eq 0) { " ← 目前版本" } else { "" }
    Write-Host "  [$($i+1)] $t  ($($dt.ToString('yyyy/MM/dd HH:mm:ss')))$label"
}

Write-Host ""
$choice = Read-Host "輸入要回復的版本編號 (1-$($tags.Count))，或按 Enter 取消"

if (-not $choice -or $choice -notmatch "^\d+$" -or [int]$choice -lt 1 -or [int]$choice -gt $tags.Count) {
    Write-Host "已取消。" -ForegroundColor Yellow
    exit 0
}

$target = $tags[[int]$choice - 1]
Write-Host ""
Write-Host "即將回復到 $target，此操作會覆蓋目前版本。" -ForegroundColor Yellow
$confirm = Read-Host "確定嗎？輸入 YES 繼續"

if ($confirm -ne "YES") {
    Write-Host "已取消。" -ForegroundColor Yellow
    exit 0
}

Write-Host "--- 回復中... ---" -ForegroundColor Cyan
git checkout $target -- .
git add -A
git commit -m "Rollback_to_$target"
git push -u origin main -f

Write-Host "--- 已回復到 $target，推送完成！---" -ForegroundColor Green
Write-Host "  iOS 用戶下次開啟會自動載入回復版本。" -ForegroundColor DarkCyan
