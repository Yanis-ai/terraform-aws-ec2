#!/bin/bash

mkdir -p ./testfiles  # ?��testfiles��?�i�@�ʕs���݁j

for ((i=1; i<=1000; i++))
do
  # ?���꘢��ܐ������e�I1MB����
  head -c 1M /dev/urandom > "test_file_$i.txt"

  if (( $i % 100 == 0 ))
  then
    archive_name="test_files_${i}_$(($i-99)).tar.gz"  # �X�V�����������?
    file_list=$(seq -f "test_file_%g.txt" $(($i-99)) $i)  # �X�V�����������?
    tar -czvf "./testfiles/$archive_name" $file_list
    rm $file_list
  fi
done