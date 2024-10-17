#!/bin/bash

SCRIPT="./../backup.sh"
BACKUP_FOLDER="./backup"
TEST_FOLDER="test_folder"

LOGFILE="test.log"
OUTPUT_FILE="output.log"

> "$LOGFILE"
> "$OUTPUT_FILE"

test_archive() {
    echo "Starting test 1 (archive)" >> "$LOGFILE"

    mkdir -p "$TEST_FOLDER"
    touch "$TEST_FOLDER/file1" "$TEST_FOLDER/file2"

    echo "Creating test files..." >> "$LOGFILE"
    dd if=/dev/zero of="$TEST_FOLDER/file1" bs=512 count=3 > /dev/null 2>&1
    dd if=/dev/zero of="$TEST_FOLDER/file2" bs=512 count=1 > /dev/null 2>&1

    { echo "$TEST_FOLDER"; echo 100; echo 2; } | "$SCRIPT" >> "$OUTPUT_FILE" 2>&1
    local return_code=$?

    if ! [ $return_code -eq 0 ] || ! ls "$BACKUP_FOLDER"/backup_*.tar.gz 1> /dev/null 2>&1; then
        echo "Test failed: Archive not created. Return code: $return_code" >> "$LOGFILE"
        cat "$OUTPUT_FILE" >> "$LOGFILE"
        return
    fi

    echo "Archive was created" >> "$LOGFILE"

    for file in "$TEST_FOLDER/file1" "$TEST_FOLDER/file2"; do
        if [ -f "$file" ]; then
            echo "Test failed: File $file was not deleted." >> "$LOGFILE"
            return
        fi
    done
    echo "Both files were removed" >> "$LOGFILE"
    echo "Test 1 passed" >> "$LOGFILE"
}

test_do_not_archive() {
    echo "Starting test 2 (do not archive)" >> "$LOGFILE"

    mkdir -p "$TEST_FOLDER"
    touch "$TEST_FOLDER/file1" "$TEST_FOLDER/file2"

    echo "Creating test files..." >> "$LOGFILE"
    dd if=/dev/zero of="$TEST_FOLDER/file1" bs=100 count=1 > /dev/null 2>&1
    dd if=/dev/zero of="$TEST_FOLDER/file2" bs=100 count=1 > /dev/null 2>&1

    { echo "$TEST_FOLDER"; echo 70; echo 2; } | "$SCRIPT" >> "$OUTPUT_FILE" 2>&1
    local return_code=$?

    if ! [ $return_code -eq 0 ]; then
        echo "Test failed: Return code: $return_code" >> "$LOGFILE"
        cat "$OUTPUT_FILE" >> "$LOGFILE"
        return
    fi

    if ls "$BACKUP_FOLDER"/backup_*.tar.gz 1> /dev/null 2>&1; then
        echo "Test failed: Archive was created." >> "$LOGFILE"
        cat "$OUTPUT_FILE" >> "$LOGFILE"
        return
    fi
    echo "Archive was not created" >> "$LOGFILE"

    if [ ! -f "$TEST_FOLDER/file1" ] || [ ! -f "$TEST_FOLDER/file2" ]; then
        echo "Test failed: One or both files are missing." >> "$LOGFILE"
        if [ ! -f "$TEST_FOLDER/file1" ]; then
            echo "File1 is missing." >> "$LOGFILE"
        fi
        if [ ! -f "$TEST_FOLDER/file2" ]; then
            echo "File2 is missing." >> "$LOGFILE"
        fi
        return
    fi

    echo "Both files still here" >> "$LOGFILE"
    echo "Test 2 passed" >> "$LOGFILE"
}

cleanup() {
    echo "Cleaning up test folders and backup..." >> "$LOGFILE"
    rm -rf "$TEST_FOLDER"
    rm -rf "$BACKUP_FOLDER"
    echo "Cleanup completed." >> "$LOGFILE"
}

test_archive
cleanup

test_do_not_archive
cleanup
