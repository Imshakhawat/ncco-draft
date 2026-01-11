@echo off
setlocal enabledelayedexpansion

set "outputFile=image_collection.json"
echo [ > %outputFile%

set "first=1"
set "counter=1"

:: Loop through png and jpg files
for %%F in (*.png *.jpg *.jpeg) do (
    set "oldName=%%~nxF"
    set "ext=%%~xF"
    
    :: Convert to Snake Case using PowerShell
    for /f "usebackq tokens=*" %%N in (`powershell -Command "'%%~nF'.ToLower().Replace(' ', '_')"`) do set "newName=%%N!ext!"
    
    :: Rename the file
    if not "!oldName!"=="!newName!" (
        ren "!oldName!" "!newName!"
    )

    :: Extract Metadata using PowerShell
    for /f "usebackq tokens=1-3 delims=," %%A in (`powershell -Command ^
        "[Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-Null; ^
        $img = [System.Drawing.Image]::FromFile('!newName!'); ^
        $size = (Get-Item '!newName!').Length; ^
        Write-Output \"$($img.Width),$($img.Height),$size\""`) do (
        set "width=%%A"
        set "height=%%B"
        set "size=%%C"
    )

    :: Add to JSON (adding comma if not first item)
    if defined first (
        set "first="
    ) else (
        echo   , >> %outputFile%
    )

    echo   { >> %outputFile%
    echo     "indexno": !counter!, >> %outputFile%
    echo     "name": "!newName!", >> %outputFile%
    echo     "height": !height!, >> %outputFile%
    echo     "width": !width!, >> %outputFile%
    echo     "type": "%%~xF", >> %outputFile%
    echo     "size_bytes": !size!, >> %outputFile%
    echo     "url": "./!newName!" >> %outputFile%
    echo   } >> %outputFile%

    set /a counter+=1
)

echo ] >> %outputFile%

echo Done! Processed !counter! images. Created %outputFile%.
pause