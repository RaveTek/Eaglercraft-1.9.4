#!/bin/bash

# Define paths
JAR_PATH="versions/1.9.4/1.9.4.jar"
ZIP_PATH="versions/1.9.4/1.9.4.zip"
OUTPUT_JS="javascript/classes.js"
TEMP_JS="javascript/temp.js"
EXTRACT_DIR="extracted_classes"
BACKUP_JS="javascript/classes_backup.js"

# Create output file and backup if it exists
if [[ -e $OUTPUT_JS ]]; then
    echo "Creating backup of $OUTPUT_JS as $BACKUP_JS..."
    cp "$OUTPUT_JS" "$BACKUP_JS"
else
    # Create an empty output file if it doesn't exist
    echo "// Merged JavaScript from TeaVM" > "$OUTPUT_JS"
fi

# Rename the .jar to .zip
echo "Renaming $JAR_PATH to $ZIP_PATH..."
cp "$JAR_PATH" "$ZIP_PATH"

# Extract the contents of the ZIP file
echo "Extracting classes from $ZIP_PATH..."
unzip -q "$ZIP_PATH" -d "$EXTRACT_DIR"

# Delete the temporary zip file
rm "$ZIP_PATH"

# Find and process each .class file
find "$EXTRACT_DIR" -name "*.class" | while read -r CLASS_PATH; do
    CLASS_NAME="${CLASS_PATH#$EXTRACT_DIR/}"
    CLASS_NAME="${CLASS_NAME//\//.}"
    CLASS_NAME="${CLASS_NAME%.class}"

    # Run TeaVM for each class
    echo "Converting $CLASS_NAME..."
    java -jar teavm-cli-0.6.0.jar -t javascript -f "$TEMP_JS" -e "$CLASS_NAME" -p "$JAR_PATH" -m --sourcemaps

    # Check if TeaVM succeeded
    if [[ $? -ne 0 ]]; then
        echo "TeaVM conversion failed for $CLASS_NAME. Skipping..."
        continue
    fi

    # Merge the output into the main file if conversion succeeded
    cat "$TEMP_JS" >> "$OUTPUT_JS"
    echo >> "$OUTPUT_JS"
done

# Cleanup
if [[ -e $TEMP_JS ]]; then
    rm "$TEMP_JS"
fi
if [[ -d $EXTRACT_DIR ]]; then
    rm -r "$EXTRACT_DIR"
fi

echo "Conversion complete. Output saved to $OUTPUT_JS. Backup saved as $BACKUP_JS."
