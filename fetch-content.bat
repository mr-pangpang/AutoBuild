:: 开启命令回显，方便调试（工作流中可看到每步执行过程）
@echo on

:: 1. 定义核心变量（显式打印，确认变量值）
set "fetch_url=https://tv-1.iill.top/m3u/Gather"
:: 强制指定 GitHub 工作流的仓库根目录（避免路径解析偏差）
set "workspace=%GITHUB_WORKSPACE%"
set "target_file=%workspace%\Gather.txt"

:: 2. 打印关键信息到日志（工作流中可查看，确认路径是否正确）
echo ============== 环境信息 ==============
echo 当前工作目录：%cd%
echo 仓库根目录（GITHUB_WORKSPACE）：%workspace%
echo 目标文件路径：%target_file%
echo 抓取链接：%fetch_url%
echo ======================================

:: 3. 确保仓库目录存在（容错处理）
if not exist "%workspace%" (
    echo 仓库目录不存在，创建目录：%workspace%
    mkdir "%workspace%"
) else (
    echo 仓库目录已存在：%workspace%
)

:: 4. 优化 curl 抓取逻辑（增加超时、显式指定用户代理，适配 GitHub 网络）
echo 开始抓取内容...
curl -L ^
  --connect-timeout 30 ^  # 连接超时30秒，避免网络慢导致失败
  --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0" ^  # 模拟浏览器，避免被目标服务器拦截
  -o "%target_file%" ^  # 输出到目标文件
  "%fetch_url%" ^
  -v  # 输出详细请求日志（工作流中可查看是否成功连接服务器）

:: 5. 抓取结果判断 + 验证文件是否存在/非空
if %errorlevel% equ 0 (
    echo curl 执行成功！
    :: 检查目标文件是否存在
    if exist "%target_file%" (
        :: 检查文件是否非空（避免下载到空文件）
        for %%F in ("%target_file%") do if %%~zF gtr 0 (
            echo 目标文件正常，大小：%%~zF 字节
            exit /b 0
        ) else (
            echo 错误：下载的文件为空！
            exit /b 1
        )
    ) else (
        echo 错误：目标文件不存在！
        exit /b 1
    )
) else (
    echo 错误：curl 抓取失败，错误码：%errorlevel%
    exit /b 1
)
