#!/bin/bash

SCRIPT="./../backup.sh"
BACKUP_FOLDER="./backup"

LOGFILE="test.log"
OUTPUTFILE="output.log"

> "$LOGFILE"
> "$OUTPUTFILE"

run_test() {
    local test_folder="$1"
    local expected_archive="$2"
    local max_percentage="$3"
    local files_to_remove="$4"

    echo "Starting test for folder: $test_folder" >> "$LOGFILE"

    mkdir -p "$test_folder"
    touch "$test_folder/file1" "$test_folder/file2"

    echo "Creating test files..." >> "$LOGFILE"
    dd if=/dev/zero of="$test_folder/file1" bs=512 count=3 > /dev/null 2>&1
    dd if=/dev/zero of="$test_folder/file2" bs=512 count=2 > /dev/null 2>&1

    { echo "$test_folder"; echo "$max_percentage"; echo "$files_to_remove"; } | "$SCRIPT" >> "$OUTPUTFILE" 2>&1
    local return_code=$?

    if [ $return_code -eq 0 ] && [ -f "$expected_archive" ]; then
        echo "Test passed: Archive created successfully at $expected_archive." >> "$LOGFILE"
    else
        echo "Test failed: Archive not created. Return code: $return_code" >> "$LOGFILE"
        cat "$OUTPUTFILE" >> "$LOGFILE"
    fi

    for file in "$test_folder/file1" "$test_folder/file2"; do
        if [ -f "$file" ]; then
            echo "Test failed: File $file was not deleted." >> "$LOGFILE"
        fi
    done
    echo "Files deletion check completed for test: $test_folder" >> "$LOGFILE"
}

cleanup() {
    echo "Cleaning up test folders and backup..." >> "$LOGFILE"
    rm -rf "test_folder"
    rm -rf "$BACKUP_FOLDER"
    echo "Cleanup completed." >> "$LOGFILE"
}

test_folder="test_folder"
backup_file="$BACKUP_FOLDER/backup_$(date +%Y_%m_%d_%H:%M:%S).tar.gz"

run_test "$test_folder" "$backup_file" 100 2

cleanup

echo "TESTS COMPLETED" >> "$LOGFILE"
