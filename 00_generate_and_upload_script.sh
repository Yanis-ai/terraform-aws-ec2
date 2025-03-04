#!/bin/bash

mkdir -p ./testfiles  # ?建testfiles目?（如果不存在）

for ((i=1; i<=1000; i++))
do
  # ?建一个包含随机内容的1MB文件
  head -c 1M /dev/urandom > "test_file_$i.txt"

  if (( $i % 100 == 0 ))
  then
    archive_name="test_files_${i}_$(($i-99)).tar.gz"  # 更新了文件序号范?
    file_list=$(seq -f "test_file_%g.txt" $(($i-99)) $i)  # 更新了文件序号范?
    tar -czvf "./testfiles/$archive_name" $file_list
    rm $file_list
  fi
done