@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Не указан путь к директории.
    exit /b 1
)
if "%~2"=="" (
    echo Не указан процент допустимой заполненности папки.
    exit /b 1
)
if "%~3"=="" (
    echo Не указано количество файлов для архивирования и удаления.
    exit /b 1
)

set max_size=1073741824
:: Путь к директории
set "test_dir=%~1"
:: Процент заполненности папки
set "maximum=%~2"
:: Число архивируемых и удаляемых файлов
set "N=%~3"

set /a Ncheck = !N!
if !Ncheck! LSS 0 (
    echo Введено неверное значение.
    exit /b 1
)
set /a maximumcheck = !maximum!
if !maximumcheck! GTR 100 (
    echo Введено неверное значение.
    exit /b 1
)
if !maximumcheck! LSS 0 (
    echo Введено неверное значение.
    exit /b 1
)




set size=0
:: Считается размер папки log
for /f "tokens=*" %%x in ('dir /s /a /b "%test_dir%\log"') do set /a size+=%%~zx
echo Размер папки: !size! байт
:: Считается максимальный допустимый размер папки по проценту заполненности до одного знака после запятой
for /f %%a in ('powershell -command "[math]::Round((%max_size%*%maximum%)/100, 1)"') do set threshold=%%a
:: Заменяем запятую на точку для корректного сравнения
set threshold=!threshold:,=.!
:: Преобразуем допустимую заполненность папки в целое число
for /f %%a in ('powershell -command "[math]::Floor(%threshold%)"') do set threshold1=%%a

if !size! geq !threshold1! (
    echo Размер всех файлов превышает !threshold1! байт.
    for /L %%i in (1,1,!N!) do (
        for /f "delims=" %%f in ('powershell -command "Get-ChildItem -Path '%test_dir%\log' -File | Sort-Object LastWriteTime | Select-Object -First 1 | ForEach-Object { $_.FullName }"') do (
            echo Архивируем файл: %%f
            "C:\Program Files\7-Zip\7z.exe" a "%test_dir%\backup\backup_%%i.7z" %%f
            del %%f
            echo Файл %%f заархивирован в "%test_dir%\backup\backup_%%i.7z" и удалён из исходной папки.
            )
        )
    set size_itog=0
    for /f "tokens=*" %%x in ('dir /s /a /b "%test_dir%\log"') do set /a size_itog+=%%~zx
    echo Размер папки после архивации и удаления: !size_itog! байт
) else (
    echo Архивирование не требуется.
)
endlocal
pause