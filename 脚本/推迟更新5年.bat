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