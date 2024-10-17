#!/bin/bash

SCRIPT="./../backup.sh"
BACKUP_FOLDER="./backup"
TEST_FOLDER="test_folder"

BUFFER_FILE="output.log"
LOG_FILE="$1"

if [ -z "$LOG_FILE" ]; then
    LOG_FILE="/dev/stdout"
fi

> "$BUFFER_FILE"
> "$LOG_FILE"

test_archive() {
    echo "Starting test 1 (archive)" >> "$LOG_FILE"

    mkdir -p "$TEST_FOLDER"
    touch "$TEST_FOLDER/file1" "$TEST_FOLDER/file2"

    echo "Creating test files..." >> "$LOG_FILE"
    dd if=/dev/zero of="$TEST_FOLDER/file1" bs=513 count=1 > /dev/null 2>&1
    dd if=/dev/zero of="$TEST_FOLDER/file2" bs=513 count=1 > /dev/null 2>&1

    { echo "$TEST_FOLDER"; echo 100; echo 2; } | "$SCRIPT" >> "$BUFFER_FILE" 2>&1
    local return_code=$?

    if ! [ $return_code -eq 0 ] || ! ls "$BACKUP_FOLDER"/backup_*.tar.gz 1> /dev/null 2>&1; then
        fail "Test failed: Archive not created. Return code: $return_code"
        return
    fi

    echo "Archive was created" >> "$LOG_FILE"

    for file in "$TEST_FOLDER/file1" "$TEST_FOLDER/file2"; do
        if [ -f "$file" ]; then
            msg "Test failed: File $file was not deleted."
            return
        fi
    done
    echo "Both files were removed" >> "$LOG_FILE"
    echo "Test 1 passed" >> "$LOG_FILE"
}

test_do_not_archive() {
    echo "Starting test 2 (do not archive)" >> "$LOG_FILE"

    mkdir -p "$TEST_FOLDER" >> "$LOG_FILE"
    touch "$TEST_FOLDER/file1" "$TEST_FOLDER/file2" >> "$LOG_FILE"

    echo "Creating test files..." >> "$LOG_FILE"
    dd if=/dev/zero of="$TEST_FOLDER/file1" bs=100 count=1 > /dev/null 2>&1
    dd if=/dev/zero of="$TEST_FOLDER/file2" bs=100 count=1 > /dev/null 2>&1

    { echo "$TEST_FOLDER"; echo 70; echo 2; } | "$SCRIPT" >> "$BUFFER_FILE" 2>&1
    local return_code=$?

    if ! [ $return_code -eq 0 ]; then
        fail "Test failed: Return code: $return_code"
        return
    fi

    if ls "$BACKUP_FOLDER"/backup_*.tar.gz 1> /dev/null 2>&1; then
        fail "Test failed: Archive was created."
        return
    fi
    echo "Archive was not created" >> "$LOG_FILE"

    if [ ! -f "$TEST_FOLDER/file1" ]; then
        fail "File1 is missing."
        return
    fi

    if [ ! -f "$TEST_FOLDER/file2" ]; then
        fail "File2 is missing."
        return
    fi

    echo "Both files still here" >> "$LOG_FILE"

    echo "Test 2 passed" >> "$LOG_FILE"
}

remove_only_oldest() {
    echo "Starting test 3 (taken_number_of_files_to_archive_less_then_need)" >> "$LOG_FILE"

    mkdir -p "$TEST_FOLDER" >> "$LOG_FILE"
    touch -t 202301011000 "$TEST_FOLDER/file1" >> "$LOG_FILE"
    touch "$TEST_FOLDER/file2" >> "$LOG_FILE"

    echo "Creating test files..."  >> "$LOG_FILE"
    dd if=/dev/zero of="$TEST_FOLDER/file1" bs=2000 count=1 > /dev/null 2>&1
    dd if=/dev/zero of="$TEST_FOLDER/file2" bs=2000 count=1 > /dev/null 2>&1

    { echo "$TEST_FOLDER"; echo 1; echo 1; } | "$SCRIPT" >> "$BUFFER_FILE" 2>&1
    local return_code=$?

    if ! [ $return_code -eq 0 ]; then
        fail "Test failed: Return code: $return_code"
        return
    fi

    if ! ls "$BACKUP_FOLDER"/backup_*.tar.gz 1> /dev/null 2>&1; then
        fail "Test failed: Archive was not created."
        return
    fi
    echo "Archive was created"  >> "$LOG_FILE"

    if [ ! -f "$TEST_FOLDER/file2" ]; then
        fail "Test failed: newest fail was deleted"
        return
    fi

    if [ -f "$TEST_FOLDER/file1" ]; then
        fail "Test failed: oldest fail was deleted"
        return
    fi

    echo "Test 3 passed"  >> "$LOG_FILE"
}

fail() {
    msg="$1"
    echo "$msg" >> "$LOG_FILE"
    echo "///backup output:///" >> "$LOG_FILE"
    cat "$BUFFER_FILE" >> "$LOG_FILE"
    echo "////////////////////" >> "$LOG_FILE"
}

cleanup() {
    echo "Cleaning up test folders and backup..."  >> "$LOG_FILE"
    rm -rf "$TEST_FOLDER"
    rm -rf "$BACKUP_FOLDER"
    rm -rf "$BUFFER_FILE"
    echo "Cleanup completed." >> "$LOG_FILE"
}

test_archive
cleanup

test_do_not_archive
cleanup

remove_only_oldest
cleanup