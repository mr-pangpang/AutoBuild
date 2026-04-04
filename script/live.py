import requests
import json

def decrypt_and_view(target_url):
    """
    解密并查看文本内容，同时清理注释行和特定字段，并在最后添加指定内容
    """
    decrypt_api = "http://www.xn--sss604efuw.com/jm/jiemi.php"
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    try:
        response = requests.get(decrypt_api, params={'url': target_url}, headers=headers, timeout=30)
        
        if response.status_code == 200:
            content = response.text.strip()
            
            # 清理注释行
            content = clean_comments(content)
            
            # 第一步：删除 ads 和 lives 字段
            content = remove_specific_fields(content, ['"ads"', '"lives"'])
            
            # 第二步：删除空白行
            content = remove_blank_lines(content)
            
            # 第三步：解析JSON并重新组织结构
            content = reorganize_json_structure(content)
            
            # 第四步：删除 proxy 字段
            content = remove_specific_fields(content, ['"proxy"'])
            
            # 第五步：在内容最后添加指定字段
            content = add_custom_fields(content)
            
            # 显示处理后的内容
            print(content)
        else:
            print(f"解密失败，状态码: {response.status_code}")
            
    except Exception as e:
        print(f"错误: {e}")

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
        # 查找字段开始位置
        start_pos = content.find(field)
        if start_pos == -1:
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
    
    return '\n'.join(non_blank_lines)

def reorganize_json_structure(content):
    """
    重新组织JSON结构，将指定项目移动到"本地播放"之后
    """
    # 首先尝试找到完整的JSON对象
    try:
        # 找到JSON的开始和结束
        json_start = content.find('{')
        json_end = content.rfind('}')
        
        if json_start == -1 or json_end == -1:
            return content
            
        # 提取整个JSON内容
        json_content = content[json_start:json_end+1]
        
        # 解析JSON
        data = json.loads(json_content)
        
        # 检查是否包含sites字段
        if 'sites' not in data:
            return content
            
        sites = data['sites']
        
        # 找到要移动的三个项目和目标位置
        items_to_move = []
        remaining_items = []
        target_position = -1
        
        for i, site in enumerate(sites):
            key = site.get('key', '')
            
            if key == '本地播放':
                target_position = i
            
            if key in ['我的夸克', '瓜子看球', '88看球']:
                items_to_move.append(site)
            else:
                remaining_items.append(site)
        
        if target_position == -1 or not items_to_move:
            return content
        
        # 重新构建sites数组
        new_sites = []
        
        for i, site in enumerate(remaining_items):
            new_sites.append(site)
            # 在"本地播放"之后插入要移动的项目
            if site.get('key') == '本地播放':
                new_sites.extend(items_to_move)
        
        # 更新数据
        data['sites'] = new_sites
        
        # 重新生成JSON字符串
        new_json = json.dumps(data, ensure_ascii=False, indent=2)
        
        # 替换原内容
        new_content = content[:json_start] + new_json + content[json_end+1:]
        
        return new_content
        
    except json.JSONDecodeError:
        # 如果JSON解析失败，使用字符串处理方法
        return reorganize_with_string_ops(content)
    except Exception:
        return content

def reorganize_with_string_ops(content):
    """
    使用字符串操作重新组织结构（JSON解析失败时的备用方法）
    """
    # 定义要移动的三个项目的完整文本
    items_to_move = [
        '''{"key":"我的夸克","name":"🗽我的┃夸克","type":3,"api":"csp_MyQuarkGuard","searchable":0,"quickSearch":0,"changeable":0,"filterable":0,"indexs":0,"style":{"type":"list"},
"timeout":30}''',
        '''{"key":"瓜子看球","name":"⚽瓜子┃看球","type":3,"api":"csp_GzSportGuard","searchable":0,"quickSearch":0,"changeable":0,"style":{"type":"list"},
"timeout":10}''',
        '''{"key":"88看球","name":"⚽88┃看球","type":3,"api":"csp_KanqiuGuard","searchable":0,"quickSearch":0,"changeable":0,"style":{"type":"list"},
"timeout":10}'''
    ]
    
    # 完整的"本地播放"项目
    local_play_item = '''{"key":"本地播放","name":"🐼本地┃播放","type":3,"api":"csp_LocalGuard","searchable":0,"changeable":0,"indexs":0,"style":{"type":"list"},
"timeout":5}'''
    
    # 第一步：从内容中删除这三个项目
    for item in items_to_move:
        # 清理item字符串以便搜索
        clean_item = item.replace('\n', '').replace(' ', '')
        clean_content = content.replace('\n', '').replace(' ', '')
        
        # 查找并删除
        pos = clean_content.find(clean_item)
        if pos != -1:
            # 找到原始位置
            orig_pos = content.find(item[:50])
            if orig_pos != -1:
                # 找到项目的结束位置
                end_pos = content.find('}', orig_pos)
                if end_pos != -1:
                    end_pos += 1
                    # 检查是否有逗号
                    if end_pos < len(content) and content[end_pos] == ',':
                        end_pos += 1
                    content = content[:orig_pos] + content[end_pos:]
    
    # 第二步：找到"本地播放"项目并在这之后插入
    # 先找到完整的本地播放项目
    local_pos = content.find(local_play_item)
    if local_pos != -1:
        # 找到项目的结束位置
        end_pos = local_pos + len(local_play_item)
        # 确保有逗号
        if end_pos < len(content) and content[end_pos] != ',':
            content = content[:end_pos] + ',\n' + content[end_pos:]
            end_pos += 2
        
        # 构建要插入的内容
        insert_content = ',\n'.join(items_to_move)
        
        # 插入到本地播放之后
        content = content[:end_pos] + ',\n' + insert_content + content[end_pos:]
    
    return content

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
	{"name":"冰茶TV","type":0,"url":"https://fy.188766.xyz/?ip=&mima=bingcha1130&json=true","playerType":2,"timeout":10,"ua":"bingcha/1.1"}
	]
}'''
    
    # 如果原内容末尾有逗号，先去掉
    if content.rstrip().endswith(','):
        content = content.rstrip()[:-1]
    
    # 添加逗号和自定义内容
    if not content.rstrip().endswith(','):
        content = content.rstrip() + ','
    
    content += custom_content
    
    return content

# 使用
if __name__ == "__main__":
    decrypt_and_view("http://ok213.top/tv")
