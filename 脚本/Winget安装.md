### 下载地址

https://learn.microsoft.com/zh-cn/windows/apps/windows-app-sdk/downloads

https://github.com/microsoft/winget-cli/releases

### 操作

首先双击执行这个主程序：

`WindowsAppRuntimeInstall-x64.exe`

完成后，执行：

```
cd C:\winget\

dir

Add-AppxPackage -Path "C:\winget\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

winget --version

```

> 安装包存放位置，根据自己的定义！





---



### Windows 10 WinGet 一键安装脚本

> `powershell` 脚本，脚本后缀 `.ps1`
>
> ⚠️ 脚本生成，目前还未校验是否可行！

> 这个脚本会自动在 C:\winget_setup 创建目录，从微软官方和 GitHub 拉取最新的 WinGet 本体以及它在 Win10 上所需的全部底层依赖（包括你之前缺少的框架），并自动完成部署。



Install_wget.ps1

> 保险起见，我脚本保存时转换为了 UTF-8 with BOM 格式！

```powershell
# ==========================================
# 0. 强制接管控制台编码 (彻底解决中文乱码)
# ==========================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# ==========================================
# 1. 自动获取管理员权限
# ==========================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (!$isAdmin) {
    Write-Host "请求管理员权限中..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ==========================================
# 2. 创建并进入工作目录
# ==========================================
$Path = "C:\winget_setup"
if (!(Test-Path $Path)) { New-Item -ItemType Directory -Force -Path $Path | Out-Null }
Set-Location $Path

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ==========================================
# 3. 智能网络请求 (带镜像回退机制)
# ==========================================
# 定义一个下载函数：直连失败就自动用镜像
function Download-FileWithFallback ($Url, $OutFile) {
    try {
        Write-Host "正在下载: $OutFile (尝试直连...)" -ForegroundColor Gray
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -ErrorAction Stop
        Write-Host "  -> 直连下载成功!" -ForegroundColor Green
    } catch {
        Write-Host "  -> 直连失败，尝试切换至国内镜像加速节点..." -ForegroundColor Yellow
        $ProxyUrl = "https://mirror.ghproxy.com/" + $Url
        try {
            Invoke-WebRequest -Uri $ProxyUrl -OutFile $OutFile -ErrorAction Stop
            Write-Host "  -> 镜像加速下载成功!" -ForegroundColor Green
        } catch {
            Write-Host "  -> 镜像下载也失败了，请检查网络或开启/关闭 VPN 后重试。" -ForegroundColor Red
            Pause
            exit
        }
    }
}

# 获取最新版本信息
Write-Host "正在连接 GitHub 获取 WinGet 最新版本信息..." -ForegroundColor Cyan
try {
    $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest" -ErrorAction Stop
} catch {
    Write-Host "无法连接到 GitHub API！当前可能处于无 VPN 状态或遭到限流。" -ForegroundColor Red
    Write-Host "建议：开启 VPN 后重试，或等待几分钟。" -ForegroundColor Red
    Pause
    exit
}

$installerUrl = ($latestRelease.assets | Where-Object { $_.name -like "*.msixbundle" }).browser_download_url
$runtimeUrl = ($latestRelease.assets | Where-Object { $_.name -match "Microsoft\.WindowsAppRuntime.+x64\.msix" }).browser_download_url
$uiXamlUrl = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
$vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" # 微软官方直连，通常不需代理

Write-Host "`n--- 开始下载核心组件 ---" -ForegroundColor Cyan
# 使用我们写的智能函数下载 GitHub 上的文件
Download-FileWithFallback -Url $installerUrl -OutFile "winget.msixbundle"
Download-FileWithFallback -Url $uiXamlUrl -OutFile "UIXaml.appx"
if ($runtimeUrl) { 
    Download-FileWithFallback -Url $runtimeUrl -OutFile "WindowsAppRuntime.msix" 
}

# 微软官方域名直连下载 VCLibs
Write-Host "正在下载: VCLibs.appx (微软官方源...)" -ForegroundColor Gray
Invoke-WebRequest -Uri $vcLibsUrl -OutFile "VCLibs.appx"
Write-Host "  -> 下载成功!" -ForegroundColor Green

# ==========================================
# 4. 执行安装
# ==========================================
Write-Host "`n--- 开始安装依赖项与本体 ---" -ForegroundColor Cyan
try {
    Write-Host "安装 VCLibs..."
    Add-AppxPackage -Path ".\VCLibs.appx" -ErrorAction Stop

    Write-Host "安装 UI.Xaml..."
    Add-AppxPackage -Path ".\UIXaml.appx" -ErrorAction Stop

    if (Test-Path ".\WindowsAppRuntime.msix") { 
        Write-Host "安装 WindowsAppRuntime..."
        Add-AppxPackage -Path ".\WindowsAppRuntime.msix" -ErrorAction Stop
    }

    Write-Host "安装 WinGet 本体..." -ForegroundColor Yellow
    Add-AppxPackage -Path ".\winget.msixbundle" -ErrorAction Stop

    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "WinGet 部署完成！" -ForegroundColor Green
    Write-Host "你可以重新打开一个普通的 PowerShell 窗口，输入 winget 测试是否生效。" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green

    # 可选：清理安装包
    Set-Location "C:\"
    Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue

} catch {
    Write-Host "安装过程中发生错误: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
```



> 转换编码示例：

![image-20260418120341819](https://raw.githubusercontent.com/duanxueli08-cell/Obsidian-Images/main/img/image-20260418120341819.png)
