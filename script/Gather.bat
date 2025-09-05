@echo off
setlocal enabledelayedexpansion

:: 下载链接
set "original_url=https://tv-1.iill.top/m3u/Gather"

:: 直接获取URL内容并显示
echo 正在获取URL内容...
echo.
echo ==================== 内容开始 ====================
echo.

:: 使用curl获取内容并直接输出到控制台
curl -L "%original_url%"

if !errorlevel! equ 0 (
    echo.
    echo ==================== 内容结束 ====================
    echo 获取成功！
) else (
    echo.
    echo 获取失败！错误代码: !errorlevel!
    exit /b !errorlevel!
)

pause
