import os
import re
import shutil
import tempfile
import subprocess
import urllib.parse
from pathlib import Path

# === 基础配置区 ===
VAULT_PATH = r"C:\Program Files\Obsidian\data\Obsidian_Vault"
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
                print("\n[?] 你的图床非常干净，无需任何清理。")
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

            print("\n[?] 大功告成！已成功为你的图床减负。")

        except Exception as e:
            print(f"\n[X] 脚本执行发生异常: {e}")

    # TemporaryDirectory 退出时会自动清理文件夹，无需手动干预
    print("[-] 临时文件已自动清理完毕。")

if __name__ == "__main__":
    main()