

## 注意事项



第一：最好不要动 Microsoft store ，也不要在里面下载任何安装包；

> 这是导致 Sysprep（系统准备工具）报错失败的头号杀手。Windows 封装时，系统会检查 Appx（UWP应用）包的挂载情况。如果某个应用只为当前用户安装或更新过，Sysprep 无法将其泛化（Generalize）到所有用户，直接就会报严重错误。

第二：用 Administrator 管理员用户，其他的普通用户删除；

> 封装必须在系统内置的最高权限 Administrator 账户下进行。存在多用户配置文件会导致权限错乱和 Sysprep 泛化失败。最标准的做法是在安装系统到 OOBE 阶段（也就是让你选国家、起名字那个界面）时，直接按 Ctrl + Shift + F3，系统会自动重启并以 Administrator 身份进入审核模式（Audit Mode），此时完全没有普通用户的干扰。

第三：如果是在虚拟机中封装，封装前记得把 VMware tools 这些虚拟工具删除！

> 虚拟机的 Tools 包含了针对虚拟网卡、虚拟显卡的底层驱动。如果不卸载就封装，部署到实体机时，系统会带着虚拟机的驱动去匹配实体机的物理硬件，极大可能导致部署阶段蓝屏（BSOD）或严重卡顿。

第四：关闭 Windows 自动更新和 Defender

> 在封装前，最好用工具或者组策略彻底关闭 Windows Update，并临时关闭 Windows Defender，防止在打包过程中系统文件被锁死或篡改。Windows 10/11 会在后台偷偷静默更新驱动、偷偷下载微软商店的内置应用（比如 Candy Crush、TikTok），这会直接触发第一条，导致封装失败。

第五：不要安装任何硬件驱动

> 在虚拟机里，除了系统自带的泛用驱动，不要手动安装任何显卡、网卡、主板的驱动程序。驱动包（如万能驱动助理）应该在封装工具设置的部署阶段再去调用，而不是直接安装在母盘里。

第六：杀毒软件最后装（或干脆不装）

> 360、火绒、迈克菲等杀毒软件会接管系统的底层权限和注册表。如果带着它们封装，可能会拦截封装工具修改系统引导和注册表的行为，导致部署后无限重启。建议把杀毒软件的安装包放在桌面上，部署完成后再手动安装，或者利用静默安装包在系统部署的最后阶段调用。

第七：软件安装在 C 盘 （这个是废话，软件肯定安装在系统盘啊！）

> 封装的软件尽量使用默认路径（通常是 C 盘）。不要把软件装在 D 盘，因为你无法保证别人电脑的硬盘分区情况，万一部署的机器只有 C 盘，装在 D 盘的软件快捷方式就会全部失效。

第八：在封装前要祛激活系统，使系统处于未激活状态；

> KMS 或数字权利激活会在系统里留下当前虚拟机的硬件特征（HWID）。封装前的系统不需要激活，激活的动作应该交给部署完成后的激活工具来做。

第九：深度清理垃圾

> 封装前，清空回收站、删除系统临时文件（%temp%）、删除 C:\Windows\SoftwareDistribution\Download 下的补丁缓存，这样能大幅缩小最终镜像（.wim 或 .esd）的体积。




##### VMware

>  如果用虚拟机可能会遇到这个问题：
>  不能正常加载系统，而系统本身没有问题，那么试一试改这两个选项：

![image-20260420152538171](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260420152538171.png)



## 封装前优化



### 桌面位置变更

> 这样桌面上的文件就不会挤占系统盘的资源了！
>
> 如果安装系统后，对方用普通用户操作系统，那就……%#@！歪比巴布

![image-20260420171248831](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260420171248831.png)









## 新时代封装 (sky)

> 之前一直都是敲命令，刚开始用这个不习惯，但是上手后发现真的牛逼！
>
> 人家这个不需要敲命令不说，封装成功率非常高！最关键的是不需要自己写答应文件了，这个直接就帮你弄好了！



### 第一步

> 系统优化和安装软件什么的，自己弄好，这里就不演示了，直接封装；
>
> 打开软件点击设置，界面上其他的不用动（系统盘乱放的，自个儿想办法！）

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417213940382.png)

A

> 基本上也不用动，看自己的需求，如果不懂，就抄我这个作业！然后封装。

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417214317993.png)



> 然后弹出这个界面，没事的话就封装完关机，看自己需求！（封装完关机，就不能再打开了哦！）

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417214542494.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417214624273.png)



### 第二步

> 再次进入，就需要从 PE 系统对封装的系统进行操作了！
>
> 进入 BIOS 启动界面，选择启动盘

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417215408358.png)



> 在 PE 系统打开该软件（所以需要准备两个硬盘，一个是系统盘，一个是空置盘），接下来进行无人值守自动化参数调试；
>
> 再次打开封装软件，点击设置；至于系统路径，它会自动锚定！

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417215640522.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417215952128.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417220015132.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417220214720.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417220344747.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417220405256.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417220428296.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417220455720.png)



> 确认好，没问题就保存吧！

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417220517847.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417220625793.png)





### 第三步

> 这一步是生成 WIM 文件；
>
> 这里我少画了一个箭头，那就是——分区备份，这才是封装的最后一步；
>
> 而左边的——映像恢复，是将封装好的镜像生成系统；

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417221401003.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417222644794.png)

> 再次确定一下，没问题就——一键备份

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417222825558.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417223000928.png)



> 好了，静静的等着！听听风扇的呼啸吧！

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417223137778.png)



> 这一步封装需要的时间比较长，封装的系统盘越大，时间就越长！所以我先干点别的事情。

![image-20260420150315448](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260420150315448.png))

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417221844082.png)



> 最后将 WIM 文件剪辑或者拷贝到宿主机中！
>
> 穿山甲：哈哈😄，我滴任务完成了！





## 开机优化



### 文件管理

![image-20260420180433016](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260420180433016.png)





### 延迟更新

推迟更新5年.bat

```powershell
@echo off
title 延长 Windows 更新暂停时间 (1825天)
color 0A

:: 1. 检查管理员权限 (修改 HKLM 必须要有管理员权限)
echo 正在检查权限...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] 已获取管理员权限。
) else (
    color 0C
    echo [错误] 权限不足！请右键点击此文件，选择 "以管理员身份运行"！
    echo.
    pause
    exit /b
)

:: 2. 核心操作：修改注册表键值
echo.
echo 正在写入注册表配置...
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v FlightSettingsMaxPauseDays /t REG_DWORD /d 1825 /f

:: 检查注册表是否写入成功
if %errorLevel% == 0 (
    echo [OK] 注册表修改成功！最大暂停时间已扩充至 1825 天 (约 5 年)。
) else (
    color 0C
    echo [错误] 注册表修改失败，请检查是否被杀毒软件或防护机制拦截。
    echo.
    pause
    exit /b
)

:: 3. 自动重启资源管理器以应用更改
echo.
echo 正在重启 Windows 资源管理器使设置立即生效...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe

echo.
echo ===================================================
echo 魔法已施放完毕！请前往“设置 - Windows 更新”查看效果。
echo ===================================================
pause
```



### 开通权限

> 通过工具确定微软更新已经延迟、安全防护已经停止

![image-20260420175528100](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260420175528100.png)



> 确定防火墙已经关闭；

![image-20260420175742574](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260420175742574.png)

> 把那些没用的通知关闭；

![image-20260420175905348](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260420175905348.png)

![image-20260420180052033](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260420180052033.png)







### 下载安装顺序

下载地址
```powershell
# 夸克
https://pan.quark.cn/s/405fb584666c

# 阿里云
https://www.alipan.com/s/Zi8UwYxYfWj
提取码：fs15

# 百度云
https://pan.baidu.com/s/1PQN8K-lj17tNjXcJpSI5Kg?pwd=duan

# 推荐网址（作用不大！）
https://www.rjctx.com/
```


#### 第一梯队

> 尽量不要在微软商店下载软件，除非仅此一家！
>
> 因为微软商店强制将软件下载到当前用户的 Appdate 文件夹下，对我来说，不方便管理！

```powershell
# 微软商店
	# Windows Terminal
	# 1Remote
```

winget

> 这个其实没必要下载，但是若是下载，尽量更改默认安装路径！

```powershell
# 修改默认安装路径
# 输入指令：winget settings 打开 winget 的配置文件 settings.json
# 在这个 JSON 文件的大括号 {} 内部，添加或修改 installBehavior 字段，如下所示：
{
    "installBehavior": {
        "preferences": {
            "scope": "machine"
        }
    }
}
# 保存并关闭该文件。
# 改完这个设置后，以后你使用 winget install 安装软件时，必须以“管理员身份”运行命令提示符或 PowerShell。

---

# 如果不想修改全局设置，也可以在每次安装时手动加上 --scope 参数：
# 临时覆盖指令：winget install <软件名> --scope machine （或者简写为 -m）。
```

![image-20260420183634040](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260420183634040.png)



#### 第二梯队

```powershell
# 7z
# Clash
# Python
# git
# Visual Studio Code
# PotPlayer
# localsend		# 局域网传输神器
# sumatraPDF
# Bitwarden		# 密码管理软件
# 微信输入法
# ContextMenuManager
# XtraToolsPortable
# Foxmail
# notepad--		# 或者 notepad++ 也行！
# Typora
# Bucd			# 这个……不好说啊！
```



#### 第三梯队

```powershell
# Obsidian
	# excalidraw
	# git
	# image auto upload
# piclist
```



#### 第四梯队

```powershell
# EVC			# 一个便捷的录屏软件
# UU远程
# WindTerm		# 远程连接工具
# AOMEIBackupper
# 火狐浏览器
# ventoy		# 制作系统盘的神器
# 语雀
# WPS （专业改良版）
# 夸克云盘
# 阿里云盘
# 天翼云盘
# CE修改器
# Telegram
# BiliTools
# Snipaste		# 截屏软件
# SwitchHosts （如果不干运维，估计 forever 用不上了！）
# Game Cheats Manager
# Mybase		# 这个装不装，看心情吧！
# VMware
# 图吧工具箱
# Todesk		# 我是不用，可是有的人需要啊！唉……
# steam			# 可有可无！！
```













## 旧时代封装



### 封装工具

```powershell
Anyburn						（必选，也可以是其他的替代品）
VMware Workstation Pro		（必选，也可以是其他的替代品）
Optimizer-16.7				（可选）
Dism++10.1.1002.1B			（可选）
一个pe系统，一个目标修改系统
```



### 封装指令

#### 封装命令

```powershell
slmgr /upk 

slmgr /cpky 

cd C:\Windows\System32\Sysprep

sysprep.exe /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\autounattend.xml


--- 解释 ——


slmgr /upk          # 卸载产品密钥(可选)
slmgr /cpky         # 清除注册表中的密钥（可选）

cd C:\Windows\System32\Sysprep
./sysprep.exe /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\autounattend.xml
# 进入sysprep.exe文件所在的目录进行封装
```



#### 导出镜像

```powershell
dism /capture-image /imagefile:E:\install.wim /capturedir:D:\ /name:"Windows10_Custom"
```

> D盘表示系统盘，E盘表示捕捉后的文件存放盘

> 只要指令在 PE 环境下执行成功（进度条走到 100% 并且没有报错），打开 E 盘根目录，就会看到这个名为 `install.wim` 的文件。注意，这个文件通常会非常大（可能好几个 GB 到十几 GB 不等，具体取决于你在捕获前，系统盘里装了多少软件和文件）。
>
> 最后需要把官方原版 ISO 镜像里 `sources` 文件夹下的那个原版 `install.wim` 删掉，**用刚才生成的这个 `install.wim` 替换进去**。





***

---





### 无人值守

#### 方法 A 

>用 **autounattend.xml**（推荐，最可靠）

把一个自动应答文件 `autounattend.xml` 放在安装介质（USB/ISO）的根目录，Windows Setup 会在启动时自动读取并按配置跳过提示。

**最小可用示例**（把整个文件保存为 `autounattend.xml`）：

```xml
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <!-- 在 windowsPE / specialize 两个阶段配置 -->
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral"
               versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <UserData>
        <AcceptEula>true</AcceptEula>
        <!-- 留空 ProductKey 并将 WillShowUI 设为 Never，避免显示输入 UI -->
        <ProductKey>
          <WillShowUI>Never</WillShowUI>
        </ProductKey>
      </UserData>
    </component>
  </settings>

  <settings pass="specialize">
    <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <!-- 跳过自动激活（仅安装阶段跳过提示，激活仍需后来处理） -->
      <SkipAutoActivation>true</SkipAutoActivation>
    </component>
  </settings>
</unattend>
```

要点／优点：

- Windows Setup 启动后会读取并跳过“输入密钥”的界面（WillShowUI 控制是否显示 UI）。文档说明可用性：Microsoft Docs（WillShowUI／ProductKey）。([Microsoft Learn](![image-20260420](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-userdata-productkey-willshowui?utm_source=chatgpt.com))
- 可以在 `specialize` 阶段再做更多自定义（如注入密钥、设置主机名等）。
- 不会在安装时把非法密钥写入镜像；只是避免交互提示。安装后需用正确密钥激活。

注意：

- 在 Windows 安装过程中，**必须命名为 `autounattend.xml`**，而不能使用 `unattend.xml` 或其他文件名。这个文件名有特定的要求和作用。
- **`autounattend.xml`** 是 Windows 安装过程中自动读取的文件名，安装程序会在安装开始时自动检测到它，并根据其中的配置来进行自动化安装。
- 文件名 **`unattend.xml`** 通常是用在 Windows 部署服务（WDS）、MDT（Microsoft Deployment Toolkit）等环境中的，通常不是在标准安装介质（USB 或 ISO）中自动加载的名称。
- **`unattend.xml`**：通常用于批量部署环境（如 WDS 或 MDT），并不是自动执行的文件，而是需要在部署过程中特别调用或指定。

#### 结论：

- **对于普通的 Windows 安装 ISO 或 USB 启动介质**，必须使用 **`autounattend.xml`**，否则文件中的配置不会被自动读取。
- **如果你只想跳过产品密钥输入并自动化安装**，确保命名文件为 **`autounattend.xml`**，并将其放到安装介质的根目录。

------

### 方法 B 

> 用 `ei.cfg` / `PID.txt` 控制（简单、快速）

将下面的文件放到 ISO 的 `sources` 目录下可以影响安装器对版本和密钥的处理。

**ei.cfg**（指定版本和频道）示例（放 `sources\ei.cfg`）：

```ini
[EditionID]
IoTEnterpriseS

[Channel]
Retail

[VL]
0
```

**PID.txt**（放 `sources\PID.txt`）可以预先填写产品密钥（可选）。如果你不填任何 key，某些安装器/版本会允许跳过输入，但行为不一。MS 文档说明了 ei.cfg 与 PID.txt 的用途。([Microsoft Learn](![image-20260420](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-edition-configuration-and-product-id-files--eicfg-and-pidtxt?view=windows-11&utm_source=chatgpt.com))

要点／优点：

- 适合只想控制“默认安装版本 / 跳过选择版本”的场景。
- 简单、无需 XML。

注意：

- 新版安装器（例如某些 24H2 installer）对 ei.cfg 的处理有所变化，可能不会按预期工作 —— 若遇到新版安装器不尊重 ei.cfg，请改用 autounattend。([Reddit](![image-20260420](https://www.reddit.com/r/Operatingsystems/comments/1fy2ae0/new_24h2_windows_os_installer_wont_let_you_choose/?utm_source=chatgpt.com))

------

> 正确的 `PID.txt` 配置方式

> **PID.txt** 文件只能包含你在安装过程中使用的 **产品密钥**，比如：

```
[PID]
ProductKey=KBN8V-HFGQ4-MGXVD-347P6-PDQGT
```

这样配置后，Windows 安装程序会在安装过程中读取 **`PID.txt`** 中的产品密钥并自动进行安装，而不会要求用户手动输入密钥。

------

- **在安装时推荐将方案一与方案二并行使用，两个不是非此即彼的关系！而且我在安装时还是需要输入产品密钥，说明pid与xml并没有生效！**
- **补充：pid没有生效不清楚，但是xml文件应该是放错位置了！**
- **目录结构应该是这样的：**

```
USB或ISO的根目录/
├── autounattend.xml  ← 您的应答文件放在这里
├── boot/
├── efi/
├── sources/
├── bootmgr
└── ...其他安装文件
```

- **而在vmware中安装时，我放置在了C:\Windows\System32\Sysprep目录下，导致文件失效！**
- **之前一直存在的问题 “安装的时候显示输入的产品密钥与可用于安装的任何可用windows映像都不匹配” 得到解决，我估计是EI.CFG文件生效了！**


**如何定义EI.CFG文件，需要查看映像文件版本信息：**

dism /get-wiminfo /wimfile:F:\系统封装教程\install.wim

>F:\系统封装教程\install.wim 这个是存放install.wim文件的路径，根据实际情况更改。

dism /get-wiminfo /wimfile:F:\系统封装教程\install.wim /index:1

> index:1 这个是索引值，根据上面的指令查看索引值。

> **继续使用 IoTEnterpriseS 映像**并且想在安装过程**跳过输入产品密钥**的提示。



