:: 原始抓取链接（可根据需求修改）
set "fetch_url=https://tv-1.iill.top/m3u/Gather"

:: 目标文件路径（GitHub 工作流中，GITHUB_WORKSPACE 是仓库根目录）
set "target_file=%GITHUB_WORKSPACE%\Gather.txt"

:: 创建目标目录（仓库根目录，容错处理）
if not exist "%GITHUB_WORKSPACE%" mkdir "%GITHUB_WORKSPACE%"

:: 执行抓取（使用 curl，GitHub  runner 已预装）
echo 开始从链接抓取内容...
curl -L -o "%target_file%" "%fetch_url%"

:: 判断抓取结果
if %errorlevel% equ 0 (
    echo 抓取成功！文件已保存到：%target_file%
    exit /b 0
) else (
    echo 抓取失败！请检查链接有效性或网络状态
    exit /b 1
)
