# ==========================================
# 0. 强制接管控制台编码 (彻底解决中文乱码)
# ==========================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# ==========================================
# 1. 管理员权限检查与自动提权
# ==========================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (!$isAdmin) {
    Write-Host "正在请求管理员权限..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ==========================================
# 2. 环境准备
# ==========================================
$WorkPath = "C:\Store_Installer"
if (!(Test-Path $WorkPath)) { New-Item -ItemType Directory -Force -Path $WorkPath | Out-Null }
Set-Location $WorkPath

# 开启 TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ==========================================
# 3. 核心下载配置 (多镜像轮询)
# ==========================================
$RawUrl = "https://github.com/kkkgo/LTSC-Add-MicrosoftStore/archive/refs/heads/master.zip"
# 备用镜像列表
$Mirrors = @(
    "https://mirror.ghproxy.com/",        # 推荐：最稳定
    "https://ghps.cc/",                   # 备选1
    "https://gh.api.99988866.xyz/",        # 备选2
    ""                                    # 最后尝试直连 (适合开启 VPN 时)
)

$ZipFile = "MicrosoftStore_LTSC.zip"
$DownloadSuccess = $false

Write-Host "--- 开始下载微软商店工具包 (文件较大，请耐心等待) ---" -ForegroundColor Cyan

foreach ($Mirror in $Mirrors) {
    $TargetUrl = $Mirror + $RawUrl
    try {
        if ($Mirror -eq "") { Write-Host "尝试 GitHub 官方直连..." -ForegroundColor Gray }
        else { Write-Host "尝试加速镜像: $Mirror" -ForegroundColor Gray }
        
        # 使用 -ErrorAction Stop 触发 catch
        Invoke-WebRequest -Uri $TargetUrl -OutFile $ZipFile -TimeoutSec 300 -ErrorAction Stop
        
        # 检查下载的文件是否过小 (如果只有几KB通常是下载了错误页面)
        if ((Get-Item $ZipFile).Length -gt 1MB) {
            Write-Host "成功下载安装包！" -ForegroundColor Green
            $DownloadSuccess = $true
            break
        }
    } catch {
        Write-Host "当前镜像连接超时或失败，准备切换..." -ForegroundColor Yellow
        if (Test-Path $ZipFile) { Remove-Item $ZipFile -Force }
    }
}

if (!$DownloadSuccess) {
    Write-Host "所有镜像均下载失败！请检查您的网络连接或开启 VPN。" -ForegroundColor Red
    Pause
    exit
}

# ==========================================
# 4. 解压与安装
# ==========================================
Write-Host "正在解压安装包..." -ForegroundColor Cyan
if (Test-Path ".\LTSC-Add-MicrosoftStore-master") { Remove-Item ".\LTSC-Add-MicrosoftStore-master" -Recurse -Force }
Expand-Archive -Path $ZipFile -DestinationPath ".\" -Force

# 查找解压后的 cmd 文件
$InstallerCmd = Get-ChildItem -Path ".\LTSC-Add-MicrosoftStore-master\Add-Store.cmd" -ErrorAction SilentlyContinue

if ($InstallerCmd) {
    Write-Host "准备执行安装程序。请在弹出的黑色窗口中等待完成。" -ForegroundColor Yellow
    # 使用 Start-Process 并在完成后等待
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$($InstallerCmd.FullName)`"" -Wait
    
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "执行结束！请查看开始菜单是否出现了 Store。" -ForegroundColor Green
    Write-Host "注意：如果安装后闪退，请重启电脑后再试。" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
} else {
    Write-Host "解压后的目录结构异常，未找到 Add-Store.cmd。" -ForegroundColor Red
}

# 可选清理
# Remove-Item $ZipFile -Force
Write-Host "按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")