# PowerShell script to list and execute SQL files in the Schema folder
# Author: Generated script
# Date: October 26, 2025

param(
    [string]$ServerName = "localhost",
    [string]$DatabaseName = "master",
    [string]$Username = "",
    [string]$Password = "",
    [switch]$ExecuteScripts = $false,
    [switch]$UseWindowsAuth = $true
)

# Get the current script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$schemaDir = Join-Path $scriptDir "Schema"

# Function to execute SQL file
function Execute-SqlFile {
    param(
        [string]$FilePath,
        [string]$Server,
        [string]$Database,
        [string]$User,
        [string]$Pass,
        [bool]$WindowsAuth
    )
    
    try {
        if ($WindowsAuth) {
            $connectionString = "Server=$Server;Database=$Database;Integrated Security=True;TrustServerCertificate=True;"
            Write-Host "   Executing with Windows Authentication..." -ForegroundColor Yellow
        } else {
            $connectionString = "Server=$Server;Database=$Database;User ID=$User;Password=$Pass;TrustServerCertificate=True;"
            Write-Host "   Executing with SQL Authentication..." -ForegroundColor Yellow
        }
        
        # Use sqlcmd if available
        if (Get-Command sqlcmd -ErrorAction SilentlyContinue) {
            if ($WindowsAuth) {
                $result = sqlcmd -S $Server -d $Database -E -i $FilePath -b
            } else {
                $result = sqlcmd -S $Server -d $Database -U $User -P $Pass -i $FilePath -b
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✓ Executed successfully" -ForegroundColor Green
                return $true
            } else {
                Write-Host "   ✗ Execution failed" -ForegroundColor Red
                Write-Host "   Error: $result" -ForegroundColor Red
                return $false
            }
        } else {
            # Fallback to .NET SqlConnection
            $sqlConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
            $sqlConnection.Open()
            
            $sqlContent = Get-Content -Path $FilePath -Raw
            $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($sqlContent, $sqlConnection)
            $sqlCommand.CommandTimeout = 300  # 5 minutes timeout
            
            $result = $sqlCommand.ExecuteNonQuery()
            $sqlConnection.Close()
            
            Write-Host "   ✓ Executed successfully (Rows affected: $result)" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "   ✗ Execution failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host "=== SQL Schema Scripts ===" -ForegroundColor Green
Write-Host "Directory: $schemaDir" -ForegroundColor Cyan
if ($ExecuteScripts) {
    Write-Host "Server: $ServerName" -ForegroundColor Cyan
    Write-Host "Database: $DatabaseName" -ForegroundColor Cyan
    Write-Host "Authentication: $(if ($UseWindowsAuth) { 'Windows' } else { 'SQL Server' })" -ForegroundColor Cyan
}
Write-Host ""

# Check if Schema directory exists
if (-Not (Test-Path $schemaDir)) {
    Write-Host "Error: Schema directory not found at: $schemaDir" -ForegroundColor Red
    exit 1
}

# Get all SQL files in the Schema directory
$sqlFiles = Get-ChildItem -Path $schemaDir -Filter "*.sql" | Sort-Object Name

if ($sqlFiles.Count -eq 0) {
    Write-Host "No SQL files found in the Schema directory." -ForegroundColor Yellow
} else {
    Write-Host "Found $($sqlFiles.Count) SQL file(s):" -ForegroundColor Yellow
    Write-Host ""
    
    $counter = 1
    $successCount = 0
    $failureCount = 0
    
    foreach ($file in $sqlFiles) {
        $fileSize = [math]::Round($file.Length / 1KB, 2)
        Write-Host "$counter. $($file.Name)" -ForegroundColor White
        Write-Host "   Size: $fileSize KB" -ForegroundColor Gray
        Write-Host "   Modified: $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
        
        if ($ExecuteScripts) {
            $success = Execute-SqlFile -FilePath $file.FullName -Server $ServerName -Database $DatabaseName -User $Username -Pass $Password -WindowsAuth $UseWindowsAuth
            if ($success) {
                $successCount++
            } else {
                $failureCount++
            }
        }
        
        Write-Host ""
        $counter++
    }
    
    if ($ExecuteScripts) {
        Write-Host "=== Execution Summary ===" -ForegroundColor Cyan
        Write-Host "✓ Successful: $successCount" -ForegroundColor Green
        Write-Host "✗ Failed: $failureCount" -ForegroundColor Red
        Write-Host ""
    }
}

# Display usage information
if (-not $ExecuteScripts) {
    Write-Host "=== Usage ===" -ForegroundColor Magenta
    Write-Host "To execute scripts against a database, use:" -ForegroundColor White
    Write-Host ""
    Write-Host "# Windows Authentication (default):" -ForegroundColor Gray
    Write-Host ".\list-schema-scripts.ps1 -ExecuteScripts -ServerName 'localhost' -DatabaseName 'YourDatabase'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "# SQL Server Authentication:" -ForegroundColor Gray
    Write-Host ".\list-schema-scripts.ps1 -ExecuteScripts -ServerName 'localhost' -DatabaseName 'YourDatabase' -UseWindowsAuth:`$false -Username 'sa' -Password 'YourPassword'" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "=== End of List ===" -ForegroundColor Green