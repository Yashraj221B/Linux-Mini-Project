#!/bin/bash

# Prompt user for folder names and extensions
echo "Enter folder names and extensions in this format (FolderName:ext1,ext2,...)."
echo "Example: Images:jpg,png Documents:pdf,docx TextFiles:txt"
read -p "Enter your input (leave blank for default): " folder_input

# Default behavior: Create default folders if no input is provided
if [[ -z "$folder_input" ]]; then
  folder_input="Images:jpg,png Documents:pdf,docx TextFiles:txt"
  echo "No input provided. Using default folders: $folder_input"
fi

# Prompt user for directory choice
echo "Do you want to organize files from:"
echo "1. Current directory"
echo "2. Another directory"
read -p "Enter your choice (1 or 2): " dir_choice

if [[ "$dir_choice" == "1" ]]; then
  target_directory=$(pwd)
elif [[ "$dir_choice" == "2" ]]; then
  read -p "Enter the absolute path of the directory: " target_directory
  if [[ ! -d "$target_directory" ]]; then
    echo "Invalid directory. Exiting..."
    exit 1
  fi
else
  echo "Invalid choice. Exiting..."
  exit 1
fi

echo "Organizing files from: $target_directory"

# Log file setup
log_file="file_organizer.log"
echo "$(date): Files organized from $target_directory." >> "$log_file"

# Create "UnknownDocuments" folder
unknown_dir="UnknownDocuments"
mkdir -p "$unknown_dir"

# Start the organization process
(
  # Parse user input and create folders
  for entry in $folder_input; do
    # Split folder name and extensions
    folder_name=$(echo "$entry" | cut -d':' -f1)
    extensions=$(echo "$entry" | cut -d':' -f2 | tr ',' ' ')

    moved_any_file=false

    # Check for files with each extension and move them
    for ext in $extensions; do
      if find "$target_directory" -maxdepth 1 -type f -name "*.$ext" | grep -q .; then
        mkdir -p "$folder_name"
        mv "$target_directory"/*."$ext" "$folder_name/" 2>/dev/null
        moved_any_file=true
      fi
    done

    if [[ "$moved_any_file" == true ]]; then
      echo "$folder_name: $(ls "$folder_name" 2>/dev/null)" >> "$log_file"
    else
      echo "No files moved to $folder_name." >> "$log_file"
    fi
  done

  # Move unknown documents (files that don't match the extensions) to "UnknownDocuments"
  # Exclude script file and log file from being processed
  find "$target_directory" -maxdepth 1 -type f ! -name "$(basename "$0")" ! -name "$(basename "$log_file")" | while read -r file; do
    # Extract file extension
    ext="${file##*.}"
    ext="${ext,,}"  # Convert to lowercase

    # Check if the file extension matches any known extension
    match_found=false
    for entry in $folder_input; do
      extensions=$(echo "$entry" | cut -d':' -f2 | tr ',' ' ')
      for ext_list in $extensions; do
        ext_list="${ext_list,,}"  # Convert to lowercase
        if [[ "$ext" == "$ext_list" ]]; then
          match_found=true
          break
        fi
      done
      if [[ "$match_found" == true ]]; then
        break
      fi
    done

    # If no match found, move the file to "UnknownDocuments"
    if [[ "$match_found" == false ]]; then
      mv "$file" "$unknown_dir/"
      echo "Moved $file to $unknown_dir" >> "$log_file"
    fi
  done
)  # End of background process

echo "Check $log_file for details."
