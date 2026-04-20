

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

> 自己费劲敲命令封装，还不如人家用工具点点点封装舒服，而且成功率高、效率也高！



### 第一步

> 系统优化和安装软件什么的，自己弄好，这里就不演示了，直接封装；
>
> 打开软件，点击-设置

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417213940382.png)

A

> 按照自己的需求来，不懂的抄作业！

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417214317993.png)



> 然后就是完成后关机，也可以不关机，看自己了！

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417214542494.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417214624273.png)



### 第二步

> 再次进入，就需要从 PE 系统对封装的系统进行操作了！

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417215408358.png)



> 在 PE 系统打开该软件（所以需要准备两个硬盘，一个是系统盘，一个是空置盘），点击设置，进行无人值守自动化设置；

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

> 最关键的一步，得到最终的 WIM 文件

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417221401003.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417222644794.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417222825558.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417223000928.png)

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417223137778.png)



> 这一步封装需要的时间比较长，封装的系统盘越大，时间越长！所以我先干点别的事情。

![image-20260420150315448](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260420150315448.png))

![image-20260420](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260417221844082.png)



> 最后将 WIM 文件剪辑或者拷贝到宿主机中！
>
> 穿山甲：哈哈😄，我滴任务完成了！





## 开机优化



进入注册表，修改 Windows update 更新周期；







































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



