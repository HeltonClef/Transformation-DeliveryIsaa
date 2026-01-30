# ==========================================
# PUSH TO GITHUB - PowerShell Version
# ==========================================

Write-Host "Setting up git configuration..." -ForegroundColor Yellow
git config --global user.name "HeltonClef"
git config --global user.email "heltonclef@gmail.com"

Write-Host "`nChecking git configuration..." -ForegroundColor Cyan
Write-Host "Name: $(git config --global user.name)" -ForegroundColor White
Write-Host "Email: $(git config --global user.email)" -ForegroundColor White

Write-Host "`nStaging files..." -ForegroundColor Yellow
git add .

Write-Host "`nFiles to be committed:" -ForegroundColor Cyan
git status --short | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Gray
}

Write-Host "`nCreating commit..." -ForegroundColor Yellow
git commit -m "last commit: ISAA Application Portfolio System with PowerShell menu, data validation, and automation scripts"

Write-Host "`nPushing to GitHub..." -ForegroundColor Yellow
Write-Host "Repository: https://github.com/HeltonClef/Transformation-DeliveryIsaa.git" -ForegroundColor Cyan

# Try to push
try {
    git push origin main
    Write-Host "`n✅ Successfully pushed to GitHub!" -ForegroundColor Green
} catch {
    Write-Host "`n⚠ Trying master branch instead..." -ForegroundColor Yellow
    try {
        git push origin master
        Write-Host "✅ Successfully pushed to master branch!" -ForegroundColor Green
    } catch {
        Write-Host "`n❌ Push failed. You may need to:" -ForegroundColor Red
        Write-Host "1. Check your GitHub credentials" -ForegroundColor Yellow
        Write-Host "2. Verify repository access" -ForegroundColor Yellow
        Write-Host "3. Use a personal access token" -ForegroundColor Yellow
    }
}

# Show final status
Write-Host "`n=== FINAL STATUS ===" -ForegroundColor Cyan
git log --oneline -3
Write-Host "`nYour code is now on GitHub: https://github.com/HeltonClef/Transformation-DeliveryIsaa" -ForegroundColor Green
