@echo off
chcp 65001 > nul :: 解决中文日志乱码
setlocal enabledelayedexpansion

:: ===================== 核心配置（已按需求优化，无需额外调整）=====================
set "TARGET_URL=https://tv-1.iill.top/m3u/Gather"  :: 目标抓取链接
set "SAVE_DIR=../TV"                               :: 结果保存目录（对应仓库TV文件夹）
set "OUTPUT_FILE=tv.txt"                           :: 最终输出文件名
set "LOG_FILE=fetch-tv-log.txt"                    :: 日志文件（用于排查问题）
set "TIMEOUT=30"                                   :: 网络超时时间（秒）
:: 模拟浏览器请求头（规避反爬，保持与原逻辑一致）
set "UA=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
set "REFERER=https://github.com/mr-pangpang/AutoBuild"

:: ===================== 初始化（创建目录/清理旧文件）=====================
echo ============== 任务开始：%date% %time% ============== > %LOG_FILE%
echo 目标链接：%TARGET_URL% >> %LOG_FILE%
echo 保存路径：%SAVE_DIR%/%OUTPUT_FILE% >> %LOG_FILE%

:: 1. 创建TV目录（不存在则创建，路径加引号避免含空格报错）
if not exist "%SAVE_DIR%" (
    mkdir "%SAVE_DIR%"
    echo [提示：已创建TV目录] >> %LOG_FILE%
)

:: 2. 清理旧结果文件（避免残留旧内容）
if exist "%SAVE_DIR%\%OUTPUT_FILE%" (
    del /f /q "%SAVE_DIR%\%OUTPUT_FILE%"
    echo [提示：已删除旧tv.txt文件] >> %LOG_FILE%
)

:: ===================== 核心：用PowerShell抓取内容（替代curl，无需额外安装）=====================
echo [正在请求链接...超时时间：%TIMEOUT%秒] >> %LOG_FILE%
:: 调用PowerShell执行抓取（静默模式，避免弹窗；传递环境变量确保参数正确）
powershell -Command "$progressPreference='silentlyContinue'; ^
try { ^
    Invoke-WebRequest -Uri '%TARGET_URL%' ^
                     -OutFile '%SAVE_DIR%\%OUTPUT_FILE%.tmp' ^
                     -UserAgent '%UA%' ^
                     -Referer '%REFERER%' ^
                     -TimeoutSec %TIMEOUT% ^
                     -ErrorAction Stop; ^
    exit 0; ^
} catch { ^
    echo 'PowerShell错误信息：' $_.Exception.Message >> '%LOG_FILE%'; ^
    exit 1; ^
}"

:: ===================== 验证结果（判断抓取是否成功）=====================
if %errorlevel% equ 0 (
    :: 检查临时文件是否存在
    if exist "%SAVE_DIR%\%OUTPUT_FILE%.tmp" (
        :: 获取临时文件大小（解决中文路径问题）
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
        echo [错误：临时文件不存在，PowerShell未生成结果] >> %LOG_FILE%
    )
) else (
    echo [错误：PowerShell抓取失败，错误码：%errorlevel%] >> %LOG_FILE%
    echo [建议：查看日志中“PowerShell错误信息”定位问题（如网络超时、链接失效）] >> %LOG_FILE%
)

:: ===================== 任务结束 =====================
echo ============== 任务结束：%date% %time% ============== >> %LOG_FILE%
:: 弹窗提示执行结果（本地操作时快速知晓）
if exist "%SAVE_DIR%\%OUTPUT_FILE%" (
    msg * "TV内容抓取成功！tv.txt已保存至：%SAVE_DIR%"
) else (
    msg * "抓取失败！请查看script目录下的fetch-tv-log.txt排查问题"
)

endlocal
exit /b %errorlevel%
