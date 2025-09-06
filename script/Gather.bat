@echo off
chcp 65001 > nul  :: 解决中文日志乱码（注意：BAT中注释用::，不用#）
setlocal enabledelayedexpansion

:: ===================== 核心配置（按你的需求修改）=====================
set "TARGET_URL=https://tv-1.iill.top/m3u/Gather"  # 目标抓取链接
set "SAVE_DIR=../TV"  # 结果保存路径（对应仓库的TV/目录，需确保路径存在）
set "OUTPUT_FILE=tv-source.m3u"  # 保存的文件名
set "LOG_FILE=fetch-tv-log.txt"  # 日志文件（存放在脚本所在目录）
set "TIMEOUT=30"  # 网络超时时间（秒）
:: 模拟浏览器请求头（规避反爬）
set "UA=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
set "REFERER=https://github.com/mr-pangpang/AutoBuild"  # 替换为你的仓库地址

:: ===================== 初始化（创建目录/清理旧文件）=====================
echo ============== 任务开始：%date% %time% ============== > %LOG_FILE%
echo 目标链接：%TARGET_URL% >> %LOG_FILE%
echo 保存路径：%SAVE_DIR%/%OUTPUT_FILE% >> %LOG_FILE%

:: 1. 创建TV目录（若不存在）
if not exist "%SAVE_DIR%" (  # 路径加引号，避免含空格报错
  mkdir "%SAVE_DIR%"
  echo [提示：已创建TV目录] >> %LOG_FILE%
)

:: 2. 清理旧结果文件（避免残留）
if exist "%SAVE_DIR%\%OUTPUT_FILE%" (
  del /f /q "%SAVE_DIR%\%OUTPUT_FILE%"
  echo [提示：已删除旧结果文件] >> %LOG_FILE%
)

:: ===================== 核心：用curl抓取内容（确保调用真正的curl）=====================
echo [正在请求链接...] >> %LOG_FILE%
:: 关键：用 curl.exe 明确调用工具，避免PowerShell别名冲突；路径加引号防空格
curl.exe -L ^  # 自动跟随302跳转
  -H "User-Agent: %UA%" ^
  -H "Referer: %REFERER%" ^
  -H "Accept: */*" ^
  --connect-timeout %TIMEOUT% ^
  --max-time %TIMEOUT% ^
  -o "%SAVE_DIR%\%OUTPUT_FILE%.tmp" ^  # 先存临时文件，失败不污染结果
  -v >> %LOG_FILE% 2>&1  # 详细日志写入文件（含请求/响应信息）

:: ===================== 验证结果（判断抓取是否成功）=====================
if %errorlevel% equ 0 (
  :: 检查临时文件是否存在且非空
  if exist "%SAVE_DIR%\%OUTPUT_FILE%.tmp" (
    :: 获取文件大小（解决中文目录/文件名问题）
    for /f "tokens=3 delims= " %%a in ('dir /-c "%SAVE_DIR%\%OUTPUT_FILE%.tmp" ^| findstr /i "字节"') do (
      set "FILE_SIZE=%%a"
    )
    :: 移除文件大小中的逗号（如“1,234”→“1234”）
    set "FILE_SIZE=!FILE_SIZE:,=!"
    if !FILE_SIZE! gtr 0 (
      ren "%SAVE_DIR%\%OUTPUT_FILE%.tmp" "%OUTPUT_FILE%"  # 临时文件转正
      echo [成功！文件大小：!FILE_SIZE! 字节] >> %LOG_FILE%
    ) else (
      echo [警告：抓取到空文件，可能链接无内容] >> %LOG_FILE%
      del /f /q "%SAVE_DIR%\%OUTPUT_FILE%.tmp"  # 删除空临时文件
    )
  ) else (
    echo [错误：临时文件不存在，请求失败] >> %LOG_FILE%
  )
) else (
  echo [错误：curl请求失败，错误码：%errorlevel%] >> %LOG_FILE%
)  :: 修复：补充else的闭合括号

:: 补充：任务结束日志
echo ============== 任务结束：%date% %time% ============== >> %LOG_FILE%

:: 退出脚本（返回错误码，便于CI/CD捕获结果）
endlocal
exit /b %errorlevel%
