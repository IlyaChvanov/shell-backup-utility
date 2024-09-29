#!/bin/bash

max_size=1024

# Цикл для проверки существования папки
while true; do
    read -p "Enter the path of the folder: " path
    if [ -d "$path" ]; then
        break
    else
        echo "Folder doesn't exist. Please enter a valid path."
    fi
done

# Цикл для проверки корректного значения процента
while true; do
    read -p "Enter maximum of fullness of the folder (0-100): " maximum
    if [ "$maximum" -ge 0 ] && [ "$maximum" -le 100 ]; then
        break
    else
        echo "Incorrect number of percents. Please enter a number between 0 and 100."
    fi
done


size=$(du -sb "$path" | awk '{print $1}')
echo "Size is $size byte"

threshold=$(( max_size * maximum / 100 ))

if [ "$size" -gt "$threshold" ]; then
    backup_dir="/backup"
    if [ ! -d "$backup_dir" ]; then
	backup_dir="./backup"
	mkdir -p "$backup_dir"	
    fi

    tmp_for_filepathes=$(mktemp)

# Запросить количество файлов для удаления
	while true; do
	    read -p "Enter how many files should be removed: " N
	    if [[ "$N" =~ ^[0-9]+$ ]] && [ "$N" -gt 0 ]; then
	        break
	    else
	        echo "Incorrect number, try again"
	    fi
	done

	# Создание списка файлов, отсортированных по дате создания
	find "$path" -type f -exec stat --format '%W %n' {} + | sort -n | awk '{print $2}' > "$tmp_for_filepathes"

	# Получаем только первые N файлов для архивации
	files_to_archive=($(head -n "$N" "$tmp_for_filepathes"))

	echo "Archiving and removing the following files:"
	for file in "${files_to_archive[@]}"; do
	    echo "$file"
	done

	archive_name="$backup_dir/backup_$(date +%Y_%m_%d_%H:%M:%S).tar.gz"

	if tar -czf "$archive_name" -T <(printf "%s\n" "${files_to_archive[@]}"); then
	    echo "Files have been archived to $archive_name"
	    
	    # Удаление файлов после успешной архивации
	    for file in "${files_to_archive[@]}"; do
	        rm "$file"
	        echo "Deleted: $file"
	    done
	else
	    echo "Error archiving files"
	fi

	rm -f "$tmp_for_filepathes"

fi
