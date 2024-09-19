#!/bin/bash
max_size=1024

read -p "Enter the path of the folder: " path
read -p "Enter maximum of fullness of the folder(0-100): " maximum

size=$(du -sb "$path" | awk '{print $1}')

echo "size is $size byte"

threshold=(( max_size * maximum / 100 ))

if [ "$size" -gt "$threshold" ]; then
	backup_dir="/backup"
	tmp_for_filepathes=$(mktemp)
	read -p "Enter how many files should be removed: " N
	find "$path" -type f -exec stat --format '%W %n' {} + | sort -n | awk '{print $2}' > "$tmp_for_filepathes"
