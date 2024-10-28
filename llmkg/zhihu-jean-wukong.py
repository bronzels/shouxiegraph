import os
import codecs

from openai.resources import api_key

# 读入测试数据------------------------------------------------------------------
# 指定测试数据的目录路径
# 有2个测试文件，第1个存放《悟空传》的第1~4章，第2个存放第5~7章。
directory_path = '/home/ubuntu/dataset/test_neo4j'

# 读入测试文件。
def read_txt_files(directory):
    # 存放结果的列表
    results = []
    # 遍历指定目录下的所有文件和文件夹
    for filename in os.listdir(directory):
        # 检查文件扩展名是否为.txt
        if filename.endswith(".txt"):
            # 构建完整的文件路径
            file_path = os.path.join(directory, filename)
            # 打开并读取文件内容
            with codecs.open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # 将文件名和内容以列表形式添加到结果列表
            results.append([filename, content])
    
    return results


# 调用函数并打印结果
file_contents = read_txt_files(directory_path)
for file_name, content in file_contents:
    print("文件名:", file_name)