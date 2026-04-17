<#
.SYNOPSIS
    Clean-Obsidian-Images.ps1 (Optimized Version)
.DESCRIPTION
    自动扫描 Obsidian 笔记，清理 GitHub 图床中未被引用的图片。
.AUTHOR
    Qwen / Optimized for duanxueli08-cell
#>

# === 基础配置区 ===
$VaultPath  = "C:\Program Files\Obsidian\data\Obsidian Vault\"
$RepoOwner  = "duanxueli08-cell"
$RepoName   = "Obsidian-Images"
$Branch     = "main"
$ImageSubdir= "img"
$TempPath   = "$env:TEMP\Obsidian-Images-Clean"

# === 认证配置区 ===
# 强烈建议不要把 Token 明文写在代码里。可以设置为系统环境变量，或在此处填入
$Token = $env:GITHUB_TOKEN # 如果你不想用环境变量，可以直接把这行改成 $Token = "ghp_你的Token"

if ([string]::IsNullOrWhiteSpace($Token)) {
    # 如果没配置 Token，就用普通克隆（前提是你本地配置了 Git 凭据或 SSH）
    $GithubRepoUrl = "https://github.com/$RepoOwner/$RepoName.git"
} else {
    $GithubRepoUrl = "https://$Token@github.com/$RepoOwner/$RepoName.git"
}

# 动态生成匹配正则 (自动转义特殊字符)
$RawBaseUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/$ImageSubdir/"
$RegexPattern = [regex]::Escape($RawBaseUrl) + "([^)""'>\s]+)"


try {
    Write-Host "[+] 开始执行 Obsidian GitHub 图床瘦身计划..." -ForegroundColor Cyan

    # ------------------------------------------------------------------
    # 1. 扫描本地笔记，提取引用的图片 (使用 HashSet 极大提升比对性能)
    # ------------------------------------------------------------------
    Write-Host "[1/4] 扫描本地笔记中引用的图片..."
    # 使用 HashSet，忽略大小写
    $UsedImages = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::InvariantCultureIgnoreCase)
    
    # -Filter "*.md" 的速度远快于 -Include
    Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $matches = [regex]::Matches($content, $RegexPattern, 'IgnoreCase')
        
        foreach ($m in $matches) {
            # 关键修复：URL 解码！(例如将 %20 还原为空格，否则无法与本地文件名匹配)
            $filename = [uri]::UnescapeDataString($m.Groups[1].Value)
            
            if ($filename -match '\.(png|jpg|jpeg|gif|webp|svg|bmp)$') {
                [void]$UsedImages.Add($filename)
            }
        }
    }
    Write-Host "  -> 发现 [$($UsedImages.Count)] 张正在使用的图片." -ForegroundColor Green

    # ------------------------------------------------------------------
    # 2. 克隆/同步图床仓库
    # ------------------------------------------------------------------
    Write-Host "[2/4] 同步远程图床仓库到临时目录..."
    if (Test-Path $TempPath) { Remove-Item -Recurse -Force $TempPath }
    
    # 屏蔽标准输出，只保留错误输出，让控制台更干净
    $null = git clone --quiet --branch $Branch --depth 1 $GithubRepoUrl $TempPath
    if ($LASTEXITCODE -ne 0) {
        throw "克隆仓库失败！请检查网络、仓库地址或 Token 权限。"
    }

    # ------------------------------------------------------------------
    # 3. 比对并找出冗余图片
    # ------------------------------------------------------------------
    Write-Host "[3/4] 正在比对图片数据..."
    $TargetImageDir = Join-Path $TempPath $ImageSubdir
    
    if (-not (Test-Path $TargetImageDir)) {
        Write-Host "  -> 警告: 仓库中不存在 $ImageSubdir 目录，无需清理。" -ForegroundColor Yellow
        exit 0
    }

    $AllImages = Get-ChildItem -Path $TargetImageDir -File
    Write-Host "  -> 仓库中共有 [$($AllImages.Count)] 张图片."

    $UnusedImages = @()
    foreach ($file in $AllImages) {
        # O(1) 复杂度比对，速度极快
        if (-not $UsedImages.Contains($file.Name)) {
            $UnusedImages += $file
        }
    }

    Write-Host "  -> 揪出 [$($UnusedImages.Count)] 张无家可归的冗余图片!" -ForegroundColor Magenta

    if ($UnusedImages.Count -eq 0) {
        Write-Host "[?] 你的图床非常干净，无需任何清理。" -ForegroundColor Green
        exit 0
    }

    # ------------------------------------------------------------------
    # 4. 批量删除并推送
    # ------------------------------------------------------------------
    Write-Host "[4/4] 正在物理销毁冗余图片并同步至 GitHub..."
    
    # 批量删除文件，而不是在一个一个地调用 git rm，大幅提升 I/O 效率
    foreach ($img in $UnusedImages) {
        Remove-Item $img.FullName -Force
        Write-Host "  [- 删] $($img.Name)" -ForegroundColor DarkGray
    }

    # 一次性让 Git 记录所有删除操作
    git -C $TempPath add -u "$ImageSubdir"
    git -C $TempPath config user.name "Obsidian Auto Cleaner"
    git -C $TempPath config user.email "cleaner@obsidian.local"
    
    # 提交并推送
    $commitMsg = "Auto clean: remove $($UnusedImages.Count) unused images"
    $null = git -C $TempPath commit -q -m $commitMsg
    $null = git -C $TempPath push -q origin $Branch

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[?] 大功告成！已成功为你的图床减负。" -ForegroundColor Green
    } else {
        throw "推送到 GitHub 失败！请检查 Token 是否具有 repo 写权限。"
    }

}
catch {
    Write-Host "`n[X] 脚本执行发生异常终止: $_" -ForegroundColor Red
}
finally {
    # ------------------------------------------------------------------
    # 5. 扫尾工作：清理产生的临时文件夹
    # ------------------------------------------------------------------
    if (Test-Path $TempPath) {
        Write-Host "[-] 正在清理临时文件..." -ForegroundColor Gray
        Remove-Item -Recurse -Force $TempPath
    }
}