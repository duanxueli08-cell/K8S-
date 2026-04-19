
> 背景

先说一下背景！本地删除图片后，图床工具并不能对远端仓库进行删除；
随着工作量的增加，会造成大量的图片冗余和垃圾信息；

> 脚本说明

所以我就写了一个脚本将本地与云端仓库对比，然后将云端仓库中没有匹配到的图片进行删除，而这个脚本不是自动的或者半自动的，不会每隔一段时间执行一次，这样的功能当然可以做到，但是我为了稳妥起见，选择手动执行！

### Powershell 脚本

clean-obsidian-images.ps1

== 稳妥起见，建议将脚本转换为 UTF-8 BOM 编码 ==

```powershell
<#
.SYNOPSIS
    Clean-Obsidian-Images.ps1 (Optimized Version)
.DESCRIPTION
    自动扫描 Obsidian 笔记，清理 GitHub 图床中未被引用的图片。
.AUTHOR
    Qwen / Optimized for duanxueli08-cell
#>

# === 基础配置区 ===
$VaultPath  = "C:\Program Files\Obsidian\data\Obsidian_Vault\"
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
```



### Python 脚本

> Python 对 `UTF-8` 的支持是原生的，而且已经在读文件时显式指定了 `encoding='utf-8'`
>
> 相比于 powershell ，Python 的性能更强！

clean-obsidian-images.py

```powershell
python clean_images.py
```

```powershell
import os
import re
import shutil
import tempfile
import subprocess
import urllib.parse
from pathlib import Path

# === 基础配置区 ===
VAULT_PATH = r"C:\Program Files\Obsidian\data\Obsidian Vault"
REPO_OWNER = "duanxueli08-cell"
REPO_NAME = "Obsidian-Images"
BRANCH = "main"
IMAGE_SUBDIR = "img"

# 强烈建议将 Token 配置在系统环境变量 GITHUB_TOKEN 中
# 如果不方便用环境变量，可以取消下一行的注释并填入你的 Token
# TOKEN = "ghp_你的Token"
TOKEN = os.environ.get("GITHUB_TOKEN", "")

if TOKEN:
    GITHUB_REPO_URL = f"https://{TOKEN}@github.com/{REPO_OWNER}/{REPO_NAME}.git"
else:
    GITHUB_REPO_URL = f"https://github.com/{REPO_OWNER}/{REPO_NAME}.git"

RAW_BASE_URL = f"https://raw.githubusercontent.com/{REPO_OWNER}/{REPO_NAME}/{BRANCH}/{IMAGE_SUBDIR}/"

def run_git_command(args, cwd):
    """运行 Git 命令并捕获错误"""
    result = subprocess.run(["git"] + args, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"[错误] Git 执行失败: {' '.join(args)}")
        print(result.stderr)
        raise Exception("Git command failed")
    return result.stdout

def main():
    print("[+] 开始执行 Obsidian GitHub 图床瘦身计划 (Python 版)...")

    # 1. 扫描本地笔记中引用的图片
    print("[1/4] 扫描本地笔记中引用的图片...")
    vault_dir = Path(VAULT_PATH)
    if not vault_dir.exists():
        print(f"[-] 错误：找不到 Obsidian 仓库路径：{VAULT_PATH}")
        return

    used_images = set()
    # 动态构建正则，避免手写转义带来的麻烦
    pattern = re.compile(re.escape(RAW_BASE_URL) + r"([^)\s\"'><]+)", re.IGNORECASE)

    # 遍历所有 md 文件（强制使用 utf-8 读取，彻底杜绝乱码）
    md_files = list(vault_dir.rglob("*.md"))
    for file_path in md_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                matches = pattern.finditer(content)
                for match in matches:
                    # 核心修复：URL 解码 (将 %20 还原为空格等)
                    filename = urllib.parse.unquote(match.group(1))
                    if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.bmp')):
                        used_images.add(filename)
        except Exception as e:
            print(f"  -> 警告: 无法读取文件 {file_path.name}: {e}")

    print(f"  -> 发现 [{len(used_images)}] 张正在使用的图片。")

    # 使用 TemporaryDirectory 自动管理临时文件夹的创建和删除
    with tempfile.TemporaryDirectory(prefix="obsidian-cleaner-") as temp_dir:
        print(f"[2/4] 同步远程图床仓库到临时目录: {temp_dir} ...")
        
        try:
            # 2. 克隆仓库
            run_git_command(["clone", "--quiet", "--branch", BRANCH, "--depth", "1", GITHUB_REPO_URL, "."], cwd=temp_dir)
            
            repo_img_dir = Path(temp_dir) / IMAGE_SUBDIR
            if not repo_img_dir.exists():
                print(f"  -> 警告: 仓库中不存在 {IMAGE_SUBDIR} 目录，无需清理。")
                return

            # 3. 比对数据
            print("[3/4] 正在比对图片数据...")
            all_images = [f for f in repo_img_dir.iterdir() if f.is_file()]
            all_image_names = {f.name for f in all_images}
            print(f"  -> 仓库中共有 [{len(all_image_names)}] 张图片。")

            unused_image_names = all_image_names - used_images
            print(f"  -> 揪出 [{len(unused_image_names)}] 张无家可归的冗余图片！")

            if not unused_image_names:
                print("\n[✓] 你的图床非常干净，无需任何清理。")
                return

            # 4. 删除冗余图片并推送
            print("[4/4] 正在物理销毁冗余图片并同步至 GitHub...")
            for img_name in unused_image_names:
                img_path = repo_img_dir / img_name
                img_path.unlink() # 删除本地文件
                print(f"  [- 删] {img_name}")

            # 提交到 Git
            run_git_command(["add", "-u", IMAGE_SUBDIR], cwd=temp_dir)
            run_git_command(["config", "user.name", "Obsidian Auto Cleaner"], cwd=temp_dir)
            run_git_command(["config", "user.email", "cleaner@obsidian.local"], cwd=temp_dir)
            
            commit_msg = f"Auto clean: remove {len(unused_image_names)} unused images"
            run_git_command(["commit", "-q", "-m", commit_msg], cwd=temp_dir)
            run_git_command(["push", "-q", "origin", BRANCH], cwd=temp_dir)

            print("\n[✓] 大功告成！已成功为你的图床减负。")

        except Exception as e:
            print(f"\n[X] 脚本执行发生异常: {e}")

    # TemporaryDirectory 退出时会自动清理文件夹，无需手动干预
    print("[-] 临时文件已自动清理完毕。")

if __name__ == "__main__":
    main()
```

