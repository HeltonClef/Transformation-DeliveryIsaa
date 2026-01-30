Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ISAA Portfolio Automation System" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Run Python Validation"
Write-Host "2. Exit"
Write-Host ""

$choice = Read-Host "Select option"
if ($choice -eq "1") {
    Write-Host "Running Python script..." -ForegroundColor Green
    python Data-Cleaning-Scripts\data_validator.py
}
else {
    Write-Host "Goodbye!" -ForegroundColor Yellow
}
