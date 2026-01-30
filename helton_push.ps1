# ==========================================
# ISAA GITHUB PUSH SCRIPT
# Configured for HeltonClef
# ==========================================

Write-Host "=== Pushing ISAA System to GitHub ===" -ForegroundColor Cyan
Write-Host "User: HeltonClef (heltonclef@gmail.com)" -ForegroundColor Yellow
Write-Host "Repo: https://github.com/HeltonClef/Transformation-DeliveryIsaa.git" -ForegroundColor Yellow
Write-Host ""

# Configure git with your details
Write-Host "1. Configuring git..." -ForegroundColor Yellow
git config --global user.name "HeltonClef"
git config --global user.email "heltonclef@gmail.com"
Write-Host "   ✅ Name: HeltonClef" -ForegroundColor Green
Write-Host "   ✅ Email: heltonclef@gmail.com" -ForegroundColor Green

# Initialize git if needed
if (-not (Test-Path .\.git)) {
    Write-Host "2. Initializing git repository..." -ForegroundColor Yellow
    git init
    Write-Host "   ✅ Repository initialized" -ForegroundColor Green
} else {
    Write-Host "2. Git repository already exists" -ForegroundColor Green
}

# Add remote
Write-Host "3. Setting up remote repository..." -ForegroundColor Yellow
git remote add origin https://github.com/HeltonClef/Transformation-DeliveryIsaa.git 2>$null
Write-Host "   ✅ Remote set to: https://github.com/HeltonClef/Transformation-DeliveryIsaa.git" -ForegroundColor Green

# Stage all files
Write-Host "4. Staging files..." -ForegroundColor Yellow
git add .
$fileCount = (git status --porcelain).Count
Write-Host "   ✅ Staged $fileCount files for commit" -ForegroundColor Green

# Show what's being committed
Write-Host "`n📁 Files to commit:" -ForegroundColor Cyan
git status --short | ForEach-Object {
    $status = $_.Substring(0, 2)
    $file = $_.Substring(3)
    $icon = if ($status -like "A*") { "🆕" } 
           elseif ($status -like "M*") { "📝" }
           elseif ($status -like "D*") { "🗑️" }
           else { "📄" }
    Write-Host "   $icon $file" -ForegroundColor Gray
}

# Commit
Write-Host "`n5. Creating commit..." -ForegroundColor Yellow
git commit -m "last commit: ISAA Application Portfolio System with working PowerShell menu, data validation, and automated reporting"
Write-Host "   ✅ Committed with message: 'last commit'" -ForegroundColor Green

# Push to GitHub
Write-Host "6. Pushing to GitHub..." -ForegroundColor Yellow
Write-Host "   This may ask for your GitHub credentials..." -ForegroundColor Cyan

try {
    # Try to push
    git push -u origin main
    Write-Host "   ✅ Successfully pushed to GitHub!" -ForegroundColor Green
} catch {
    Write-Host "   ⚠ Trying alternative branch names..." -ForegroundColor Yellow
    
    # Try different branch names
    $branches = @("main", "master", "HEAD")
    $pushed = $false
    
    foreach ($branch in $branches) {
        if (-not $pushed) {
            try {
                Write-Host "   Trying $branch branch..." -ForegroundColor Gray
                git push -u origin $branch --force 2>$null
                Write-Host "   ✅ Pushed to $branch branch!" -ForegroundColor Green
                $pushed = $true
                break
            } catch {
                # Continue to next branch
            }
        }
    }
    
    if (-not $pushed) {
        Write-Host "   ❌ Could not push. You may need to:" -ForegroundColor Red
        Write-Host "      - Check internet connection" -ForegroundColor Yellow
        Write-Host "      - Verify GitHub credentials" -ForegroundColor Yellow
        Write-Host "      - Check repository permissions" -ForegroundColor Yellow
    }
}

# Final status
Write-Host "`n=== FINAL STATUS ===" -ForegroundColor Cyan
git remote -v
git log --oneline -3

Write-Host "`n🎉 Done! Check your GitHub repository:" -ForegroundColor Green
Write-Host "🔗 https://github.com/HeltonClef/Transformation-DeliveryIsaa" -ForegroundColor Yellow
