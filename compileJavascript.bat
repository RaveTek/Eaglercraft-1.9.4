@echo off
setlocal enabledelayedexpansion

:: Define paths
set "JAR_PATH=versions/1.9.4/1.9.4.jar"
set "ZIP_PATH=versions/1.9.4/1.9.4.zip"
set "OUTPUT_JS=javascript/classes.js"
set "TEMP_JS=javascript/temp.js"
set "EXTRACT_DIR=extracted_classes"
set "BACKUP_JS=javascript/classes_backup.js"

:: Check if the output file exists and create a backup if it does
if exist "%OUTPUT_JS%" (
    echo Creating backup of %OUTPUT_JS% as %BACKUP_JS%...
    copy "%OUTPUT_JS%" "%BACKUP_JS%"
) else (
    :: Create an empty output file if it doesn't exist
    echo // Merged JavaScript from TeaVM > "%OUTPUT_JS%"
)

:: Check if the JAR file exists before renaming
if exist "%JAR_PATH%" (
    echo Renaming %JAR_PATH% to %ZIP_PATH%...
    copy "%JAR_PATH%" "%ZIP_PATH%"

    :: Extract the contents of the ZIP file
    echo Extracting classes from %ZIP_PATH%...
    powershell -command "Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%EXTRACT_DIR%' -Force"

    :: Delete the temporary zip file
    del "%ZIP_PATH%"
) else (
    echo Error: %JAR_PATH% does not exist.
    exit /b 1
)

:: Find and process each .class file
for /r "%EXTRACT_DIR%" %%f in (*.class) do (
    set "CLASS_PATH=%%f"
    set "CLASS_NAME=!CLASS_PATH:%EXTRACT_DIR%=!"
    set "CLASS_NAME=!CLASS_NAME:\=.!"
    set "CLASS_NAME=!CLASS_NAME:.class=!"

    :: Run TeaVM for each class
    echo Converting !CLASS_NAME!...
    java -jar teavm-cli-0.6.0.jar -t javascript -f "%TEMP_JS%" -e "!CLASS_NAME!" -p "%JAR_PATH%" -m --sourcemaps

    :: Check if TeaVM succeeded
    if errorlevel 1 (
        echo TeaVM conversion failed for !CLASS_NAME!. Skipping...
        continue
    )

    :: Merge the output into the main file if conversion succeeded
    type "%TEMP_JS%" >> "%OUTPUT_JS%"
    echo. >> "%OUTPUT_JS%"
)

:: Cleanup
if exist "%TEMP_JS%" del "%TEMP_JS%"
if exist "%EXTRACT_DIR%" rmdir /s /q "%EXTRACT_DIR%"

echo Conversion complete. Output saved to %OUTPUT_JS%. Backup saved as %BACKUP_JS%.
pause
