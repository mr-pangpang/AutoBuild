@echo off
chcp 65001 > nul :: 解决中文日志乱码（BAT注释用::，勿用#）
setlocal enabledelayedexpansion

:: ===================== 核心配置（已按需求修改，无需额外调整）=====================
:: 目标抓取链接（固定为需求中的链接）
set "TARGET_URL=https://tv-1.iill.top/m3u/Gather"
:: 结果保存路径（对应仓库TV目录，确保与脚本路径同级：script/Gather.bat → TV/tv.txt）
set "SAVE_DIR=../TV"
:: 最终输出文件名（需求指定为tv.txt）
set "OUTPUT_FILE=tv.txt"
:: 日志文件（存于脚本所在目录，用于排查问题）
set "LOG_FILE=fetch-tv-log.txt"
:: 网络超时时间（秒，避免长时间卡停）
set "TIMEOUT=30"
:: 模拟浏览器请求头（规避反爬，已更新为最新Chrome标识）
set "UA=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
:: Referer（关联仓库地址，提升请求合法性）
set "REFERER=https://github.com/mr-pangpang/AutoBuild"
:: 【关键】指定本地可用的curl路径（需替换为你电脑中curl.exe的实际路径！）
set "CURL_PATH=C:\Program Files\curl\bin\curl.exe"

:: ===================== 初始化（创建目录/清理旧文件）=====================
:: 写入任务开始日志
echo ============== 任务开始：%date% %time% ============== > %LOG_FILE%
echo 目标链接：%TARGET_URL% >> %LOG_FILE%
echo 保存路径：%SAVE_DIR%/%OUTPUT_FILE% >> %LOG_FILE%
echo 使用curl路径：%CURL_PATH% >> %LOG_FILE%

:: 1. 创建TV目录（若不存在，路径加引号避免含空格报错）
if not exist "%SAVE_DIR%" (
    mkdir "%SAVE_DIR%"
    echo [提示：已创建TV目录] >> %LOG_FILE%
)

:: 2. 清理旧结果文件（避免残留旧内容）
if exist "%SAVE_DIR%\%OUTPUT_FILE%" (
    del /f /q "%SAVE_DIR%\%OUTPUT_FILE%"
    echo [提示：已删除旧tv.txt文件] >> %LOG_FILE%
)

:: ===================== 核心：curl抓取内容（确保调用本地可用curl）=====================
echo [正在请求链接...请耐心等待] >> %LOG_FILE%
:: 调用指定路径的curl，先存为临时文件（避免失败污染结果）
"%CURL_PATH%" -L ^
    -H "User-Agent: %UA%" ^
    -H "Referer: %REFERER%" ^
    -H "Accept: */*" ^
    --connect-timeout %TIMEOUT% ^
    --max-time %TIMEOUT% ^
    -o "%SAVE_DIR%\%OUTPUT_FILE%.tmp" ^
    -v >> %LOG_FILE% 2>&1  :: 详细日志写入文件（含请求/响应信息，便于排查）

:: ===================== 验证结果（判断抓取是否成功）=====================
if %errorlevel% equ 0 (
    :: 检查临时文件是否存在
    if exist "%SAVE_DIR%\%OUTPUT_FILE%.tmp" (
        :: 获取临时文件大小（解决中文路径/文件名问题）
        for /f "tokens=3 delims= " %%a in ('dir /-c "%SAVE_DIR%\%OUTPUT_FILE%.tmp" ^| findstr /i "字节"') do (
            set "FILE_SIZE=%%a"
        )
        :: 移除文件大小中的逗号（如“1,234”→“1234”）
        set "FILE_SIZE=!FILE_SIZE:,=!"
        
        :: 验证文件非空（避免保存空内容）
        if !FILE_SIZE! gtr 0 (
            ren "%SAVE_DIR%\%OUTPUT_FILE%.tmp" "%OUTPUT_FILE%"
            echo [成功！tv.txt已生成，文件大小：!FILE_SIZE! 字节] >> %LOG_FILE%
            echo [本地路径：%cd%\%SAVE_DIR%\%OUTPUT_FILE%] >> %LOG_FILE%
        ) else (
            echo [警告：抓取到空文件，可能目标链接无内容或IP受限] >> %LOG_FILE%
            del /f /q "%SAVE_DIR%\%OUTPUT_FILE%.tmp"  :: 删除空临时文件
        )
    ) else (
        echo [错误：临时文件不存在，curl请求未生成结果] >> %LOG_FILE%
    )
) else (
    echo [错误：curl请求失败，错误码：%errorlevel%] >> %LOG_FILE%
    echo [建议：查看日志中curl详细报错，或检查CURL_PATH是否正确] >> %LOG_FILE%
)

:: ===================== 任务结束 =====================
echo ============== 任务结束：%date% %time% ============== >> %LOG_FILE%
:: 弹窗提示执行结果（便于本地操作时快速知晓）
if exist "%SAVE_DIR%\%OUTPUT_FILE%" (
    msg * "TV内容抓取成功！tv.txt已保存至：%SAVE_DIR%"
) else (
    msg * "抓取失败！请查看script目录下的fetch-tv-log.txt排查问题"
)

endlocal
exit /b %errorlevel%
