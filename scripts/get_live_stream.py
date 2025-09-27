import requests
from bs4 import BeautifulSoup
import re
import sys

def extract_stream(url):
    headers = {'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15'}
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # 查找 m3u8/flv 链接
        patterns = [r'https?://[^\s<>"{}|\\^`[\]]+\.m3u8(?:\?[^"\s]*)?', 
                   r'https?://[^\s<>"{}|\\^`[\]]+\.flv(?:\?[^"\s]*)?']
        for pattern in patterns:
            match = re.search(pattern, response.text)
            if match:
                return match.group(0)
        return "未找到直播源"
    except Exception as e:
        return f"错误: {str(e)}"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python get_live_stream.py <url>")
        sys.exit(1)
    print(extract_stream(sys.argv[1]))
