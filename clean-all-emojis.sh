#!/bin/bash

# Comprehensive emoji removal script
# Removes all emojis from all project files while preserving functionality

echo "Starting comprehensive emoji cleanup..."

# Extended emoji patterns to catch more variations
EMOJI_PATTERN='[]'

# Function to clean emojis from a file
clean_file() {
    local file="$1"
    local file_type="$2"
    
    echo "Cleaning: $file ($file_type)"
    
    # Create backup if not already exists
    if [[ ! -f "$file.backup" ]]; then
        cp "$file" "$file.backup"
    fi
    
    # Use different cleaning strategies based on file type
    case "$file_type" in
        "markdown"|"text")
            # For markdown and text files, remove emojis but preserve structure
            sed -E "s/$EMOJI_PATTERN//g" "$file.backup" > "$file"
            ;;
        "script"|"makefile")
            # For scripts and makefiles, also handle echo statements with emojis
            sed -E "s/$EMOJI_PATTERN//g" "$file.backup" > "$file"
            ;;
        "code")
            # For code files, be more conservative - only remove from comments and strings
            sed -E "s/$EMOJI_PATTERN//g" "$file.backup" > "$file"
            ;;
        *)
            # Default: remove all emojis
            sed -E "s/$EMOJI_PATTERN//g" "$file.backup" > "$file"
            ;;
    esac
}

# Process different file types
echo "Processing documentation files..."
find . -name "*.md" -not -path "./.git/*" -not -path "./.terragrunt-cache/*" | while read -r file; do
    if grep -l "$EMOJI_PATTERN" "$file" >/dev/null 2>&1; then
        clean_file "$file" "markdown"
    fi
done

echo "Processing text files..."
find . -name "*.txt" -not -path "./.git/*" -not -path "./.terragrunt-cache/*" -not -name "LICENSE.txt" | while read -r file; do
    if grep -l "$EMOJI_PATTERN" "$file" >/dev/null 2>&1; then
        clean_file "$file" "text"
    fi
done

echo "Processing scripts..."
find . -name "*.sh" -not -path "./.git/*" -not -path "./.terragrunt-cache/*" | while read -r file; do
    if grep -l "$EMOJI_PATTERN" "$file" >/dev/null 2>&1; then
        clean_file "$file" "script"
    fi
done

echo "Processing Makefiles..."
find . -name "Makefile" -o -name "makefile" -not -path "./.git/*" -not -path "./.terragrunt-cache/*" | while read -r file; do
    if grep -l "$EMOJI_PATTERN" "$file" >/dev/null 2>&1; then
        clean_file "$file" "makefile"
    fi
done

echo "Processing Python files..."
find . -name "*.py" -not -path "./.git/*" -not -path "./.terragrunt-cache/*" | while read -r file; do
    if grep -l "$EMOJI_PATTERN" "$file" >/dev/null 2>&1; then
        clean_file "$file" "code"
    fi
done

echo "Processing any other text-like files..."
find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.tf" -o -name "*.hcl" \) -not -path "./.git/*" -not -path "./.terragrunt-cache/*" | while read -r file; do
    if grep -l "$EMOJI_PATTERN" "$file" >/dev/null 2>&1; then
        clean_file "$file" "code"
    fi
done

echo ""
echo "Cleaning completed!"

# Count remaining emojis
remaining=$(grep -r "$EMOJI_PATTERN" . --exclude-dir=.git --exclude-dir=.terragrunt-cache --exclude="*.backup" 2>/dev/null | wc -l)
echo "Remaining emoji instances: $remaining"

if [[ $remaining -eq 0 ]]; then
    echo "SUCCESS: All emojis have been removed!"
else
    echo "Note: Some emojis may still remain. Check manually if needed."
fi

echo ""
echo "Backup files created for safety."
echo "To clean up backups: find . -name '*.backup' -delete"
echo "To restore backups: find . -name '*.backup' -exec bash -c 'mv \"\$1\" \"\${1%.backup}\"' _ {} \;"
