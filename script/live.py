import requests

def decrypt_and_view(target_url):
    """
    解密并查看文本内容，同时清理注释行和特定字段，并在最后添加指定内容
    """
    decrypt_api = "http://www.xn--sss604efuw.com/jm/jiemi.php"
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    try:
        print(f"正在解密: {target_url}")
        response = requests.get(decrypt_api, params={'url': target_url}, headers=headers, timeout=30)
        
        if response.status_code == 200:
            content = response.text.strip()
            print(f"原始内容长度: {len(content)}")
            
            # 清理注释行
            content = clean_comments(content)
            print(f"清理注释后长度: {len(content)}")
            
            # 第一步：删除 ads 和 lives 字段
            content = remove_specific_fields(content, ['"ads"', '"lives"'])
            
            # 第二步：删除空白行
            content = remove_blank_lines(content)
            
            # 第三步：删除 proxy 字段
            content = remove_specific_fields(content, ['"proxy"'])
            
            # 第四步：在内容最后添加指定字段
            content = add_custom_fields(content)
            
            print(f"最终内容长度: {len(content)}")
            print("\n" + "="*50)
            print("解密后的内容:")
            print("="*50)
            print(content)
            print("="*50)
            
        else:
            print(f"❌ 解密失败，状态码: {response.status_code}")
            
    except Exception as e:
        print(f"❌ 错误: {e}")

def clean_comments(content):
    """
    清理注释行，移除以//开头的行
    """
    lines = content.split('\n')
    cleaned_lines = []
    
    for line in lines:
        stripped_line = line.strip()
        # 保留非空且不以//开头的行
        if stripped_line and not stripped_line.startswith('//'):
            cleaned_lines.append(line)
    
    return '\n'.join(cleaned_lines)

def remove_specific_fields(content, fields_to_remove):
    """
    删除特定的JSON字段
    """
    for field in fields_to_remove:
        print(f"正在删除字段: {field}")
        
        # 查找字段开始位置
        start_pos = content.find(field)
        if start_pos == -1:
            print(f"未找到字段: {field}")
            continue
            
        # 找到字段后的冒号
        colon_pos = content.find(':', start_pos)
        if colon_pos == -1:
            continue
            
        # 从冒号后开始，找到字段值的结束位置
        pos = colon_pos + 1
        brace_count = 0
        bracket_count = 0
        in_string = False
        escape_next = False
        
        while pos < len(content):
            char = content[pos]
            
            if escape_next:
                escape_next = False
            elif char == '\\':
                escape_next = True
            elif char == '"' and not escape_next:
                in_string = not in_string
            elif not in_string:
                if char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
                elif char == '[':
                    bracket_count += 1
                elif char == ']':
                    bracket_count -= 1
                elif char == ',' and brace_count == 0 and bracket_count == 0:
                    break
                elif char == '}' and brace_count == 0 and bracket_count == 0:
                    break
                elif char == ']' and brace_count == 0 and bracket_count == 0:
                    break
            
            pos += 1
        
        # 删除从字段名开始到值结束的位置
        if pos < len(content):
            content = content[:start_pos] + content[pos+1:]
        else:
            content = content[:start_pos]
        
        print(f"已删除字段: {field}")
    
    # 清理可能的多余逗号
    content = content.replace(',,', ',')
    content = content.replace(',}', '}')
    content = content.replace(',]', ']')
    
    return content

def remove_blank_lines(content):
    """
    删除空白行
    """
    lines = content.split('\n')
    non_blank_lines = []
    
    for line in lines:
        # 保留非空行（包括只有空格但不是完全空的行）
        if line.strip():
            non_blank_lines.append(line)
    
    cleaned_content = '\n'.join(non_blank_lines)
    print(f"删除空白行: {len(lines)} -> {len(non_blank_lines)} 行")
    
    return cleaned_content

def add_custom_fields(content):
    """
    在JSON内容最后添加自定义字段
    """
    # 确保内容以 } 结尾
    if content.endswith('}'):
        content = content[:-1]
    
    # 要添加的自定义内容
    custom_content = '''
"proxy":[
	"raw.githubusercontent.com",
	"googlevideo.com",
	"cdn.v82u1l.com",
	"cdn.iz8qkg.com",
	"cdn.kin6c1.com",
	"c.biggggg.com",
	"c.olddddd.com",
	"haiwaikan.com",
	"www.histar.tv",
	"youtube.com",
	"uhibo.com",
	".*boku.*",
	".*nivod.*",
	".*ulivetv.*"
	],
"hosts": [
	"hlsztemgsplive.miguvideo.com=hlsztemgsplive.miguvideo.com.b.cdn.chinamobile.com",
	"push-rtmp-hs-spe-f5.douyincdn.com=source-fcdn-spe-push.s.bytefcdn.com",
	"cdn9.163189.xyz=gcore.jsdelivr.net",
	"cache.ott.fifalive.itv.cmvideo.cn=cache.ott.fifalive.itv.cmvideo.cn.e.cdn.chinamobile.com",
	"studentlive.migucloud.com=base-v4v6-miguvideo.e.cdn.chinamobile.com"
	],
"ads":["static-mozai.4gtv.tv"],
"lives":[
{"name":"TV","type":0,"url":"https://ghproxy.net/https://raw.githubusercontent.com/dpdisk/m3u/main/tv","playerType":2,"timeout":10,"ua":"okHttp/Mod-1.4.0.0"},
{"name":"冰茶TV","type":0,"url":"https://fy.188766.xyz/?ip=&mima=mianfeibuhuaqian&json=true","playerType":2,"timeout":10,"ua":"bingcha/1.1"}
	]
}'''
    
    # 如果原内容末尾有逗号，先去掉
    if content.rstrip().endswith(','):
        content = content.rstrip()[:-1]
    
    # 添加逗号和自定义内容
    if not content.rstrip().endswith(','):
        content = content.rstrip() + ','
    
    content += custom_content
    print("✅ 已添加自定义字段")
    
    return content

# 使用
if __name__ == "__main__":
    decrypt_and_view("http://ok321.top/tv")
