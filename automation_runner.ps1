# ISAA Application Portfolio - Automation System
# Author: Oladokun Clement

# Configuration
$ProjectRoot = "C:\ISAA_Application"
$PythonScript = "$ProjectRoot\Data-Cleaning-Scripts\data_validator.py"
$OutputFolder = "$ProjectRoot\Output"
$LogFolder = "$ProjectRoot\Logs"

# Create output folders
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force }
if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder -Force }

function Show-Menu {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "    ISAA APPLICATION PORTFOLIO SYSTEM     " -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Run Data Validation Demo" -ForegroundColor Green
    Write-Host "2. Create Sample Data" -ForegroundColor Green
    Write-Host "3. View Generated Reports" -ForegroundColor Green
    Write-Host "4. Push to GitHub" -ForegroundColor Green
    Write-Host "5. Open in VS Code" -ForegroundColor Green
    Write-Host "6. Exit" -ForegroundColor Red
    Write-Host ""
}

function Run-Validation {
    Write-Host "Running data validation demo..." -ForegroundColor Cyan
    
    # Create timestamp
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $logFile = "$LogFolder\validation_$timestamp.log"
    
    # Run Python script
    Write-Host "Executing Python script..." -ForegroundColor Yellow
    python $PythonScript 2>&1 | Tee-Object -FilePath $logFile
    
    Write-Host "`n✅ Demo completed!" -ForegroundColor Green
    Write-Host "Log saved to: $logFile" -ForegroundColor Gray
    Write-Host "Check Output folder for results" -ForegroundColor Gray
    
    Pause
}

function Create-SampleData {
    Write-Host "Creating sample dataset..." -ForegroundColor Cyan
    
    $sampleData = @"
patient_id,patient_name,test_date,birth_date,temperature,phone_number,facility_code,test_result
P001,John Doe,2024-01-15,1985-03-10,36.5,08012345678,F001,Positive
P002,Jane Smith,2024-01-16,1990-07-22,37.2,+2348012345679,F002,Negative
P003,Bob Johnson,2024-01-17,1978-11-30,35.8,08033334444,F001,Positive
P004,Alice Brown,2024-01-18,2005-02-14,38.5,08123456789,F003,Negative
P005,Charlie Wilson,2024-01-19,1995-12-05,36.9,07012345678,F003,Negative
P006,David Miller,2024-01-20,1988-06-15,37.1,09012345678,F001,Positive
P007,Emma Davis,2024-01-21,1992-09-28,36.7,08098765432,F002,Negative
P008,Frank Wilson,2024-01-22,1975-04-15,37.8,07098765432,F001,Positive
P009,Grace Taylor,2024-01-23,1998-11-03,36.3,08111223344,F002,Negative
P010,Henry Brown,2024-01-24,1982-08-19,37.5,09099887766,F003,Positive
"@
    
    $sampleFile = "$OutputFolder\sample_dataset_$(Get-Date -Format 'yyyyMMdd').csv"
    $sampleData | Out-File -FilePath $sampleFile -Encoding UTF8
    
    Write-Host "✅ Sample data created: $sampleFile" -ForegroundColor Green
    Write-Host "Total records: 10" -ForegroundColor Gray
    Write-Host "Facilities: F001, F002, F003" -ForegroundColor Gray
    
    Pause
}

function View-Reports {
    Write-Host "Available Reports:" -ForegroundColor Cyan
    
    if (Test-Path $OutputFolder) {
        $files = Get-ChildItem $OutputFolder -File
        
        if ($files.Count -eq 0) {
            Write-Host "No reports found. Run validation first." -ForegroundColor Yellow
        }
        else {
            $i = 1
            foreach ($file in $files) {
                Write-Host "$i. $($file.Name)" -ForegroundColor Green
                Write-Host "   Size: $([math]::Round($file.Length/1KB, 2)) KB" -ForegroundColor Gray
                Write-Host "   Modified: $($file.LastWriteTime)" -ForegroundColor Gray
                $i++
            }
            
            $choice = Read-Host "`nEnter number to view file (or press Enter to go back)"
            if ($choice -match '^\d+$' -and [int]$choice -le $files.Count) {
                $selectedFile = $files[[int]$choice - 1]
                Write-Host "`n--- Content of $($selectedFile.Name) ---" -ForegroundColor Cyan
                Get-Content $selectedFile.FullName | Select-Object -First 20
            }
        }
    }
    
    Pause
}

function Push-ToGitHub {
    Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
    
    # Check if git is initialized
    if (-not (Test-Path ".git")) {
        Write-Host "Git not initialized. Initializing..." -ForegroundColor Yellow
        git init
        Write-Host "✅ Git initialized" -ForegroundColor Green
    }
    
    # Configure git if needed
    $userName = git config --global user.name
    $userEmail = git config --global user.email
    
    if (-not $userName) {
        Write-Host "Setting git user name..." -ForegroundColor Yellow
        git config --global user.name "Oladokun Clement"
    }
    
    if (-not $userEmail) {
        Write-Host "Setting git user email..." -ForegroundColor Yellow
        git config --global user.email "heltonclef@gmail.com"
    }
    
    # Add all files
    Write-Host "Adding files to git..." -ForegroundColor Yellow
    git add .
    
    # Commit
    $commitMessage = "Add ISAA application portfolio scripts - $(Get-Date -Format 'yyyy-MM-dd')"
    git commit -m $commitMessage
    
    Write-Host "`n✅ Ready to push to GitHub!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Create a new repository on GitHub.com" -ForegroundColor White
    Write-Host "2. Copy the remote URL (https://github.com/yourusername/ISAA-Portfolio.git)" -ForegroundColor White
    Write-Host "3. Run: git remote add origin YOUR_REPO_URL" -ForegroundColor White
    Write-Host "4. Run: git push -u origin main" -ForegroundColor White
    Write-Host "`nOr use GitHub Desktop for easier push" -ForegroundColor Gray
    
    Pause
}

function Open-InVSCode {
    Write-Host "Opening project in VS Code..." -ForegroundColor Cyan
    code .
    Write-Host "✅ VS Code should open with your project" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

# Main menu loop
do {
    Show-Menu
    $choice = Read-Host "`nSelect an option (1-6)"
    
    switch ($choice) {
        "1" { Run-Validation }
        "2" { Create-SampleData }
        "3" { View-Reports }
        "4" { Push-ToGitHub }
        "5" { Open-InVSCode }
        "6" { 
            Write-Host "Goodbye!" -ForegroundColor Yellow
            Exit 0 
        }
        default { 
            Write-Host "Invalid option. Press Enter to continue..." -ForegroundColor Red
            Pause
        }
    }
} while ($true)
