#!/bin/bash

mkdir -p ./testfiles  # ?testfilesΪ?i@ΚsΆέj

for ((i=1; i<=1000; i++))
do
  # ?κ’οάχΰeI1MBΆ
  head -c 1M /dev/urandom > "test_file_$i.txt"

  if (( $i % 100 == 0 ))
  then
    archive_name="test_files_${i}_$(($i-99)).tar.gz"  # XVΉΆδ?
    file_list=$(seq -f "test_file_%g.txt" $(($i-99)) $i)  # XVΉΆδ?
    tar -czvf "./testfiles/$archive_name" $file_list
    rm $file_list
  fi
done