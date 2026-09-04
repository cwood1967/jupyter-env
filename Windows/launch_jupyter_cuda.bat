@echo off
setlocal

REM CUDA 13.0 torch, for machines with an NVIDIA GPU. Uses its own checkout so
REM switching flavors does not force a multi-GB torch reinstall each time.
set "TORCH_EXTRA=cu130"
set "TARGET_DIR=%USERPROFILE%\Desktop\jupyter-env-cuda"

set "GIT_SOURCE=https://github.com/cwood1967/jupyter-env.git"
set "UV_CACHE_DIR=C:\pixi-cache\uv-cache"

if not exist "%UV_CACHE_DIR%" mkdir "%UV_CACHE_DIR%"

set "UV_EXE=uv"
where uv >nul 2>nul
if errorlevel 1 (
    echo uv not found - installing...
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    set "UV_EXE=%USERPROFILE%\.local\bin\uv.exe"
)
if not "%UV_EXE%"=="uv" if not exist "%UV_EXE%" (
    echo Failed to install uv. Install it manually from https://astral.sh/uv, then re-run this file.
    pause
    exit /b 1
)

if exist "%TARGET_DIR%\.git" (
    echo Updating existing uv_env checkout...
    git -C "%TARGET_DIR%" fetch origin && git -C "%TARGET_DIR%" reset --hard origin/main
) else (
    if exist "%TARGET_DIR%" (
        echo Removing incomplete previous checkout...
        rmdir /s /q "%TARGET_DIR%"
    )
    git clone "%GIT_SOURCE%" "%TARGET_DIR%"
)

set "NB_DIR=%~1"
if "%NB_DIR%"=="" (
    for /f "delims=" %%F in ('powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.ValidateNames = $false; $f.CheckFileExists = $false; $f.CheckPathExists = $true; $f.FileName = 'Select this folder'; $f.Title = 'Choose a folder to open in Jupyter'; if ($f.ShowDialog() -eq 'OK') { Split-Path $f.FileName }"') do set "NB_DIR=%%F"

)
if "%NB_DIR%"=="" (
    echo No folder selected.
    pause
    exit /b 1
)


cd /d "%TARGET_DIR%"
echo Installing the %TORCH_EXTRA% environment - the CUDA torch download is large...
"%UV_EXE%" sync --extra %TORCH_EXTRA%
if errorlevel 1 (
    echo Environment install failed.
    pause
    exit /b 1
)
REM --no-sync: uv run would otherwise re-sync without the extra and swap out torch.
"%UV_EXE%" run --no-sync jupyter lab --notebook-dir="%NB_DIR%"
