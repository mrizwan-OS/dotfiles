# ============================================================================
#                    POWERSHELL DEVELOPER PROFILE v5.0
# ============================================================================
# Clean rewrite for PWSH - No Mamba, No Micromamba
# ============================================================================

# ----------------------------------------------------------------------------
# 1. PSREADLINE ENHANCEMENTS
# ----------------------------------------------------------------------------
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    Set-PSReadLineOption -HistoryNoDuplicates -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
    Set-PSReadLineOption -BellStyle None -ErrorAction SilentlyContinue
    Set-PSReadLineOption -MaximumHistoryCount 10000 -ErrorAction SilentlyContinue

    Set-PSReadLineOption -Colors @{
        Command            = '#00ff9d'
        Number             = '#ff6e6e'
        Member             = '#ffb86c'
        Operator           = '#ff79c6'
        Type               = '#8be9fd'
        Variable           = '#f1fa8c'
        Parameter          = '#ffb86c'
        Comment            = '#6272a4'
        String             = '#50fa7b'
        Default            = '#f8f8f2'
    } -ErrorAction SilentlyContinue

    Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteChar -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord -ErrorAction SilentlyContinue
}

# ----------------------------------------------------------------------------
# 2. STATUS EMOJI FUNCTIONS
# ----------------------------------------------------------------------------
function Get-CondaEnv {
    if ($env:CONDA_DEFAULT_ENV -and $env:CONDA_DEFAULT_ENV -ne "base") {
        return "🐍 $($env:CONDA_DEFAULT_ENV)"
    }
    elseif ($env:CONDA_DEFAULT_ENV -eq "base") {
        return "🐍"
    }
    return ""
}

function Get-NodeStatus {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        return "📦 node$nodeVersion"
    }
    return ""
}

function Get-GitStatus {
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($branch) {
            $status = git status --porcelain 2>$null
            if ($status) { return "📝 $branch" } else { return "✓ $branch" }
        }
    }
    catch {}
    return ""
}

function Get-DockerStatus {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        return "🐳"
    }
    return ""
}

# ----------------------------------------------------------------------------
# 3. CUSTOM PROMPT WITH EMOJIS
# ----------------------------------------------------------------------------
function prompt {
    $currentPath = Get-Location
    $homePath = "C:\Users\rizwan"
    
    $folderName = if ($currentPath.Path -eq $homePath) { "~" } 
                  else { Split-Path $currentPath -Leaf }
    
    $statusEmojis = @()
    
    $condaStatus = Get-CondaEnv
    if ($condaStatus) { $statusEmojis += $condaStatus }
    
    $nodeStatus = Get-NodeStatus
    if ($nodeStatus) { $statusEmojis += $nodeStatus }
    
    $gitStatus = Get-GitStatus
    if ($gitStatus) { $statusEmojis += $gitStatus }
    
    $dockerStatus = Get-DockerStatus
    if ($dockerStatus) { $statusEmojis += $dockerStatus }
    
    $statusLine = if ($statusEmojis) { " [$($statusEmojis -join ' | ')]" } else { "" }
    
    $Gold = "`e[38;2;255;215;0m"
    $Cyan = "`e[38;2;0;255;255m"
    $Orange = "`e[38;2;255;165;0m"
    $BrightBlue = "`e[38;2;0;191;255m"
    $DimGray = "`e[38;2;128;128;128m"
    $Green = "`e[38;2;0;255;127m"
    $Reset = "`e[0m"
    
    $displayUser = $env:USERNAME.Substring(0,1).ToUpper() + $env:USERNAME.Substring(1).ToLower()
    
    Write-Host ""
    Write-Host "${DimGray}┌─${Reset}${Gold}${displayUser}${Reset}${DimGray}@${Reset}${Cyan}$env:COMPUTERNAME${Reset}${DimGray}:${Reset}${Orange}${folderName}${Reset}${Green}${statusLine}${Reset}" -NoNewline
    Write-Host ""
    Write-Host "${DimGray}└─${Reset}${BrightBlue}❯${Reset} " -NoNewline
    
    return " "
}

# ----------------------------------------------------------------------------
# 4. MINICONDA INTEGRATION (NO MAMBA)
# ----------------------------------------------------------------------------
$minicondaPaths = @(
    "C:\Users\rizwan\miniconda3",
    "C:\Users\rizwan\Miniconda3",
    "C:\ProgramData\miniconda3",
    "C:\tools\miniconda3"
)

$minicondaFound = $false
foreach ($condaBase in $minicondaPaths) {
    $condaExe = Join-Path $condaBase "Scripts\conda.exe"
    if (Test-Path $condaExe) {
        $env:Path = "$(Join-Path $condaBase 'Scripts');$(Join-Path $condaBase 'Library\bin');$env:Path"
        $global:condaBasePath = $condaBase
        $minicondaFound = $true
        
        # Initialize conda for PowerShell
        & "$condaBase\Scripts\conda.exe" shell.powershell hook | Out-String | Invoke-Expression
        break
    }
}

# ----------------------------------------------------------------------------
# 5. NODE.JS INTEGRATION
# ----------------------------------------------------------------------------
$nodePaths = @(
    "C:\Program Files\nodejs",
    "$env:APPDATA\npm",
    "$env:LOCALAPPDATA\Programs\nodejs"
)

foreach ($nodePath in $nodePaths) {
    if (Test-Path "$nodePath\node.exe") {
        $env:Path = "$nodePath;$env:Path"
        break
    }
}

$npmGlobal = "$env:APPDATA\npm"
if (Test-Path $npmGlobal) {
    $env:Path = "$npmGlobal;$env:Path"
}

Set-Alias -Name npm -Value 'npm.cmd' -ErrorAction SilentlyContinue
Set-Alias -Name npx -Value 'npx.cmd' -ErrorAction SilentlyContinue

# ----------------------------------------------------------------------------
# 6. MSYS2 UCRT64 PATH
# ----------------------------------------------------------------------------
$ucrt = "C:\msys64\ucrt64\bin"
if (Test-Path $ucrt) {
    $pathArray = $env:Path -split ';'
    $pathArray = @($ucrt) + ($pathArray | Where-Object { $_ -ne $ucrt })
    $env:Path = $pathArray -join ';'
}

$msys2Usr = "C:\msys64\usr\bin"
if (Test-Path $msys2Usr) {
    $pathArray = $env:Path -split ';'
    $pathArray = @($msys2Usr) + ($pathArray | Where-Object { $_ -ne $msys2Usr })
    $env:Path = $pathArray -join ';'
}

# ----------------------------------------------------------------------------
# 7. GCLOUD SDK INTEGRATION
# ----------------------------------------------------------------------------
$gcloudPaths = @(
    "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin",
    "C:\Program Files\Google\Cloud SDK\google-cloud-sdk\bin"
)

foreach ($gcloudDir in $gcloudPaths) {
    if (Test-Path $gcloudDir) {
        $env:Path = "$gcloudDir;$env:Path"
        break
    }
}

# ----------------------------------------------------------------------------
# 8. MAVEN & GRADLE
# ----------------------------------------------------------------------------
$mavenPaths = @("C:\apache-maven-*", "C:\Program Files\apache-maven-*")
foreach ($pattern in $mavenPaths) {
    $mavenDir = Get-ChildItem $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($mavenDir) {
        $env:Path = "$($mavenDir.FullName)\bin;$env:Path"
        break
    }
}

$gradlePaths = @("C:\gradle-*", "C:\Program Files\gradle-*")
foreach ($pattern in $gradlePaths) {
    $gradleDir = Get-ChildItem $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($gradleDir) {
        $env:Path = "$($gradleDir.FullName)\bin;$env:Path"
        break
    }
}

Set-Alias -Name mvn -Value 'mvn.cmd' -ErrorAction SilentlyContinue
Set-Alias -Name gradle -Value 'gradle.bat' -ErrorAction SilentlyContinue

# ----------------------------------------------------------------------------
# 9. GITHUB CLI & GO
# ----------------------------------------------------------------------------
$ghPaths = @("$env:LOCALAPPDATA\GitHubCLI\bin", "C:\Program Files\GitHub CLI\bin")
foreach ($ghDir in $ghPaths) {
    if (Test-Path "$ghDir\gh.exe") {
        $env:Path = "$ghDir;$env:Path"
        break
    }
}

$goPath = "C:\Program Files\Go\bin"
if (Test-Path $goPath) {
    $env:Path = "$goPath;$env:Path"
    $env:GOPATH = "$env:USERPROFILE\go"
    $env:GO111MODULE = "on"
}

# ----------------------------------------------------------------------------
# 10. ENHANCED ALIASES
# ----------------------------------------------------------------------------
Set-Alias -Name ll -Value Get-ChildItem -ErrorAction SilentlyContinue
Set-Alias -Name la -Value Get-ChildItem -ErrorAction SilentlyContinue
Set-Alias -Name l -Value Get-ChildItem -ErrorAction SilentlyContinue
Set-Alias -Name b -Value Set-Location .. -ErrorAction SilentlyContinue
Set-Alias -Name bb -Value Set-Location ../.. -ErrorAction SilentlyContinue
Set-Alias -Name bbb -Value Set-Location ../../.. -ErrorAction SilentlyContinue

Set-Alias -Name g -Value git -ErrorAction SilentlyContinue
Set-Alias -Name gs -Value 'git status' -ErrorAction SilentlyContinue
Set-Alias -Name ga -Value 'git add' -ErrorAction SilentlyContinue
Set-Alias -Name gaa -Value 'git add --all' -ErrorAction SilentlyContinue
Set-Alias -Name gc -Value 'git commit -m' -ErrorAction SilentlyContinue
Set-Alias -Name gp -Value 'git push' -ErrorAction SilentlyContinue
Set-Alias -Name gpl -Value 'git pull' -ErrorAction SilentlyContinue
Set-Alias -Name gd -Value 'git diff' -ErrorAction SilentlyContinue
Set-Alias -Name gl -Value 'git log --oneline --graph' -ErrorAction SilentlyContinue
Set-Alias -Name gb -Value 'git branch' -ErrorAction SilentlyContinue
Set-Alias -Name gco -Value 'git checkout' -ErrorAction SilentlyContinue

Set-Alias -Name reload -Value ". `$PROFILE" -ErrorAction SilentlyContinue
Set-Alias -Name edit-profile -Value "code `$PROFILE" -ErrorAction SilentlyContinue
Set-Alias -Name profile-file -Value "notepad `$PROFILE" -ErrorAction SilentlyContinue
Set-Alias -Name conda-activate -Value 'conda activate' -ErrorAction SilentlyContinue
Set-Alias -Name conda-deactivate -Value 'conda deactivate' -ErrorAction SilentlyContinue

# ----------------------------------------------------------------------------
# 11. UTILITY FUNCTIONS
# ----------------------------------------------------------------------------
function mkcd {
    param($path)
    New-Item -Path $path -ItemType Directory -Force | Out-Null
    Set-Location $path
    Write-Host "📁 Created & changed to: $path" -ForegroundColor Green
}

function touch {
    param($file)
    if (Test-Path $file) {
        (Get-Item $file).LastWriteTime = Get-Date
        Write-Host "🕒 Updated: $file" -ForegroundColor Green
    } else {
        New-Item -Path $file -ItemType File -Force | Out-Null
        Write-Host "📄 Created: $file" -ForegroundColor Green
    }
}

function which {
    param($command)
    Get-Command $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

function ports-list {
    Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' } | 
        Select-Object LocalPort, OwningProcess, @{Name="ProcessName";Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} |
        Format-Table -AutoSize
}

function kill-port {
    param($port)
    $process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($process) {
        Stop-Process -Id $process.OwningProcess -Force
        Write-Host "✅ Killed process on port $port" -ForegroundColor Green
    } else {
        Write-Host "❌ No process found on port $port" -ForegroundColor Red
    }
}

function Get-ToolVersions {
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    🔧 TOOL VERSIONS                        ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  ✅ PowerShell: v$($PSVersionTable.PSVersion)" -ForegroundColor Green
    $tools = @("git", "node", "npm", "python", "go", "docker", "gcc", "cmake")
    
    foreach ($tool in $tools) {
        $ver = & $tool --version 2>$null | Select-Object -First 1
        if ($ver) {
            Write-Host "  ✅ $($tool): $ver" -ForegroundColor Green
        }
    }
    
    if ($minicondaFound) {
        $condaVer = conda --version 2>$null
        Write-Host "  ✅ Miniconda: $condaVer" -ForegroundColor Green
    }
    Write-Host ""
}

function env-status {
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                    📊 ENVIRONMENT STATUS                   ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "  ⚡ PowerShell: v$($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    
    if ($env:CONDA_DEFAULT_ENV) {
        Write-Host "  🐍 Conda: $($env:CONDA_DEFAULT_ENV)" -ForegroundColor Green
    } elseif ($minicondaFound) {
        Write-Host "  🐍 Miniconda: Available" -ForegroundColor Yellow
    }
    
    $nodeVer = node --version 2>$null
    if ($nodeVer) { Write-Host "  📦 Node.js: $nodeVer" -ForegroundColor Green }
    
    $pythonVer = python --version 2>$null
    if ($pythonVer) { Write-Host "  🐍 Python: $pythonVer" -ForegroundColor Green }
    
    Write-Host "  📁 Current: $(Get-Location)" -ForegroundColor Gray
    Write-Host ""
}

Set-Alias -Name versions -Value Get-ToolVersions -ErrorAction SilentlyContinue
Set-Alias -Name env-st -Value env-status -ErrorAction SilentlyContinue

# ----------------------------------------------------------------------------
# 12. STARTUP
# ----------------------------------------------------------------------------
Clear-Host

Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║                    🚀 POWERSHELL DEVELOPER PROFILE v5.0 🚀                ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "  PowerShell: v$($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host ""
Write-Host "  ⚡ QUICK COMMANDS: versions, env-status, ports-list, kill-port" -ForegroundColor Yellow
Write-Host ""

if ($minicondaFound) {
    Write-Host "  🐍 Miniconda: $global:condaBasePath" -ForegroundColor Green
    Write-Host "     conda activate <env>  • Activate environment" -ForegroundColor DarkGray
    Write-Host ""
}

Set-Location "C:\Users\rizwan"
Write-Host "  ✨ Profile ready! ✨" -ForegroundColor Green
Write-Host ""