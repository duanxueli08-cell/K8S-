# Windows10系统封装

## 封装涉及到的工具

```powershell
Anyburn						（必选，也可以是其他的替代品）
VMware Workstation Pro		（必选，也可以是其他的替代品）
Optimizer-16.7				（可选）
Dism++10.1.1002.1B			（可选）
一个pe系统，一个目标修改系统
```



## 封装涉及到的指令

### 封装命令

```powershell
slmgr /upk          # 卸载产品密钥(可选)
slmgr /cpky         # 清除注册表中的密钥（可选）

进入sysprep.exe文件所在的目录进行封装
cd C:\Windows\System32\Sysprep

sysprep.exe /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\autounattend.xml
```

```powershell
slmgr /upk 

slmgr /cpky 

cd C:\Windows\System32\Sysprep

sysprep.exe /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\autounattend.xml
```



### 导出镜像

```powershell
dism /capture-image /imagefile:E:\install.wim /capturedir:D:\ /name:"Windows10_Custom"
```

> D盘表示系统盘，E盘表示捕捉后的文件存放盘

> 只要指令在 PE 环境下执行成功（进度条走到 100% 并且没有报错），打开 E 盘根目录，就会看到这个名为 `install.wim` 的文件。注意，这个文件通常会非常大（可能好几个 GB 到十几 GB 不等，具体取决于你在捕获前，系统盘里装了多少软件和文件）。
>
> 最后需要把官方原版 ISO 镜像里 `sources` 文件夹下的那个原版 `install.wim` 删掉，**用刚才生成的这个 `install.wim` 替换进去**。





***

---





**如何定义EI.CFG文件，需要查看映像文件版本信息：**

dism /get-wiminfo /wimfile:F:\系统封装教程\install.wim

>F:\系统封装教程\install.wim 这个是存放install.wim文件的路径，根据实际情况更改。

dism /get-wiminfo /wimfile:F:\系统封装教程\install.wim /index:1

> index:1 这个是索引值，根据上面的指令查看索引值。

> **继续使用 IoTEnterpriseS 映像**并且想在安装过程**跳过输入产品密钥**的提示。

------

### 方法 A — 用 **autounattend.xml**（推荐，最可靠）

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

### 结论：

- **对于普通的 Windows 安装 ISO 或 USB 启动介质**，必须使用 **`autounattend.xml`**，否则文件中的配置不会被自动读取。
- **如果你只想跳过产品密钥输入并自动化安装**，确保命名文件为 **`autounattend.xml`**，并将其放到安装介质的根目录。

------

### 方法 B — 用 `ei.cfg` / `PID.txt` 控制（简单、快速）

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









#### 寻医问药

这是我要定制的系统。

版本	Windows 10 IoT 企业版 LTSC
版本号	21H2

现在我想要根据这个系统定制我自己的系统盘，但是失败了！失败之处就是做好的系统启动时密钥验证不通过！这也说明我的 autounattend.xml 文件失效了！没有发挥出它的作用。帮我优化这三个文件，我想要想通过密钥验证，或者跳过验证！

另外我想把 autounattend.xml 放在 ISO 根目录下，ei.cfg 和 PID.txt 这两个文件放在 ISO 的 `sources` 目录下，是否可行？

autounattend.xml

>只用 `autounattend.xml`，这是最稳妥、最高效、且通过率最高的方案！

```powershell
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">

  <settings pass="windowsPE">
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <UserData>
        <AcceptEula>true</AcceptEula>
        <ProductKey>
          <Key>QPM6N-7J2WJ-P88HH-P3YRH-YY74H</Key>
          <WillShowUI>Never</WillShowUI>
        </ProductKey>
      </UserData>
    </component>
  </settings>

  <settings pass="specialize">
    <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <SkipAutoActivation>true</SkipAutoActivation>
    </component>
  </settings>

  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      
      <UserAccounts>
        <AdministratorPassword>
          <Value></Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
      </UserAccounts>

      <AutoLogon>
        <Password>
          <Value></Value>
          <PlainText>true</PlainText>
        </Password>
        <Enabled>true</Enabled>
        <LogonCount>9999999</LogonCount>
        <Username>Administrator</Username>
      </AutoLogon>

      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <ProtectYourPC>3</ProtectYourPC> </OOBE>

    </component>
  </settings>

</unattend>
```

ei.cfg

>Windows 10 IoT 企业版（IoTEnterpriseS）在微软的体系中，通常属于 **OEM** 授权渠道，而不是 Retail（零售版）。你的原文件写了 `Retail`，这可能会与你的密钥类型产生冲突。建议修改为 `OEM`。

```ini
[EditionID]
IoTEnterpriseS

[Channel]
OEM

[VL]
0
```

PID.txt

> 既然我们已经在 `autounattend.xml` 中指定了密钥，**建议直接删除 ISO 中的 PID.txt 文件**。 保留它不仅没有意义，反而增加未来修改时产生冲突的风险。如果坚持要保留，请确保里面的密钥与 XML 中的完全一致：

```powershell
[PID]
Value=KBN8V-HFGQ4-MGXVD-347P6-PDQGT
```



##### 无法加载系统

>  如果遇到虚拟机不能正常加载系统，而系统本身没有问题，那么试一试改这两个选项：

![image-20260420152538171](https://cdn.jsdelivr.net/gh/duanxueli08-cell/Obsidian-Images@main/img/image-20260420152538171.png)





## 达者为尊 (sky)

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
