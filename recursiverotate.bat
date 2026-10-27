
@echo off
setlocal EnableExtensions

REM ==========================================
REM Konfigurasi folder utama
REM Jika argumen folder tidak diberikan,
REM gunakan direktori tempat BAT dijalankan.
REM ==========================================

if "%~1"=="" (
    set "TARGET_DIR=%CD%"
) else (
    set "TARGET_DIR=%~1"
)

if not exist "%TARGET_DIR%\" (
    echo Error: Direktori "%TARGET_DIR%" tidak ditemukan!
    pause
    exit /b 1
)

pushd "%TARGET_DIR%" || (
    echo Error: Gagal membuka folder utama.
    pause
    exit /b 1
)

echo Folder utama: %CD%

REM ==========================================
REM Periksa setiap subfolder langsung
REM di bawah folder utama
REM ==========================================

for /d %%D in (*) do (
    if /i not "%%D"=="output" (
        call :PROCESS_FOLDER "%%D"
    )
)

echo.
echo Semua folder selesai diperiksa.

popd
pause
exit /b 0


:PROCESS_FOLDER
set "SUBDIR=%~1"

echo.
echo Memeriksa folder: "%SUBDIR%"

REM Buat folder output di dalam subfolder
if not exist "%SUBDIR%\output\" (
    mkdir "%SUBDIR%\output"
)

set "FOUND=0"

REM Proses file MP4 dan mp4
for %%F in ("%SUBDIR%\*.mp4" "%SUBDIR%\*.MP4") do (
    if exist "%%~fF" (
        if not exist "%%~fF\" (
            set "FOUND=1"
            call :PROCESS_FILE "%%~fF" "%%~nF" "%SUBDIR%"
        )
    )
)

if "%FOUND%"=="0" (
    echo Tidak ada video MP4 di folder "%SUBDIR%"
)

exit /b 0


:PROCESS_FILE
set "INPUT=%~1"
set "BASENAME=%~2"
set "SUBDIR=%~3"

echo Sedang memproses: "%INPUT%"

REM Rotasi 90 derajat berlawanan arah jarum jam
REM Audio disalin tanpa encoding ulang
ffmpeg -hide_banner -y -i "%INPUT%" -threads 2 -vf "transpose=2" -c:a copy "%SUBDIR%\output\%BASENAME%_.MP4"

if errorlevel 1 (
    echo GAGAL memproses: "%INPUT%"
) else (
    echo Selesai: "%SUBDIR%\output\%BASENAME%_.MP4"
)

REM Jeda 3 detik
timeout /t 3 /nobreak >nul

exit /b 0

