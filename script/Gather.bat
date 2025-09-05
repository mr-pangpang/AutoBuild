@echo off
setlocal enabledelayedexpansion

:: 原始GitHub链接
set "original_url=https://tv-1.iill.top/m3u/Gather"

:: 目标文件路径
set "target_file=.\Gather.txt"

:: 创建目标目录（如果不存在）
for %%F in ("%target_file%") do (
    if not exist "%%~dpF" mkdir "%%~dpF"
)

:: 下载文件
echo 正在下载...
curl -L -o "%target_file%" "%original_url%"
if !errorlevel! equ 0 (
    echo 下载成功！
    echo 文件已保存到: %target_file%
) else (
    echo 下载失败！错误代码: !errorlevel!
    exit /b !errorlevel!
)

:: pause
