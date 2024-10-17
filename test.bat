@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

if not exist backup\ mkdir backup
if not exist log\ mkdir log

set "test_dir=%~1"
set "test_log=%test_dir%\log"
set "test_backup=%test_dir%\backup"


:: Генерация тестовых файлов
set /a size=0   

:generate_files
set /a file_size=!random! %% 104857600 + 10485760
set /a size+=file_size
fsutil file createnew "%test_log%\file_!size!.bin" !file_size!
if !size! lss 1073741824 (
    goto generate_files
)

:: Запуск тестов
for /L %%i in (1,1,4) do (
    echo Запуск теста %%i...
    set /a maximum=!random! %% 100 + 1
    set /a N=!random! %% 10 + 1
    call "%test_dir%\backup.bat" "%test_dir%" !maximum! !N!
    echo Тест %%i завершен.
)

echo Все тесты завершены.
endlocal
pause