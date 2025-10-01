@echo off
chcp 65001 >nul

REM 第一步：删除tvg-id
powershell -Command "(Get-Content 'm3u' -Encoding UTF8) -replace 'tvg-id=\""[^\""]*\""', '' | Set-Content 'temp.txt' -Encoding UTF8"

REM 第二步：删除tvg-name  
powershell -Command "(Get-Content 'temp.txt' -Encoding UTF8) -replace 'tvg-name=\""[^\""]*\""', '' | Set-Content '_m3u' -Encoding UTF8"

REM 第三步：清理多余空格（将所有连续空格替换为单个空格）
powershell -Command "(Get-Content '_m3u' -Encoding UTF8) -replace ' +', ' ' | Set-Content '_m3u' -Encoding UTF8"

del temp.txt
echo 处理完成！
::pause
