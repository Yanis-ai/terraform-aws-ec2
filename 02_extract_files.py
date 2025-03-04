import os
import sys
import tarfile
import time

def extract_tar_gz(input_path, output_dir):
    """解压 .tar.gz 文件，并返回解压时间"""
    start_time = time.time()

    with tarfile.open(input_path, "r:gz") as tar:
        tar.extractall(output_dir)

    end_time = time.time()
    return round(end_time - start_time, 2)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("用法: python extract_files.py <输入文件路径> <输出目录>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_folder = sys.argv[2]

    os.makedirs(output_folder, exist_ok=True)
    duration = extract_tar_gz(input_file, output_folder)

    print(f"解压 {input_file} 用时 {duration} 秒")
