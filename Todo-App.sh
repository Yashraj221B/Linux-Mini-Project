#!/bin/bash

# Function to print colored text
print_color() {
    local color_code=$1
    local text=$2
    echo -e "\033[${color_code}m${text}\033[0m"
}

# Task file
file="tasks.txt"

# Check if tasks file exists, create if not
if [ ! -f "$file" ]; then
    touch "$file"
fi

# Function to validate if a given year is a leap year
is_leap_year() {
    local year=$1
    if (( (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0) )); then
        return 0  # Leap year
    else
        return 1  # Not a leap year
    fi
}

# Date validation loop with checks for month, day, hour, and minute
validate_due_date() {
    while true; do
        read -p "Enter Due Date (YYYY-MM-DD HH:MM): " due
        
        # Validate the general date format YYYY-MM-DD HH:MM
        if [[ "$due" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}$ ]]; then
            # Extract year, month, day, hour, and minute components
            year=$(echo "$due" | cut -d ' ' -f 1 | cut -d '-' -f 1)
            month=$(echo "$due" | cut -d ' ' -f 1 | cut -d '-' -f 2)
            day=$(echo "$due" | cut -d ' ' -f 1 | cut -d '-' -f 3)
            hour=$(echo "$due" | cut -d ' ' -f 2 | cut -d ':' -f 1)
            minute=$(echo "$due" | cut -d ' ' -f 2 | cut -d ':' -f 2)
            
            # Check if the month is between 01 and 12
            if (( month < 1 || month > 12 )); then
                print_color "1;31" "Invalid Month! Must be between 01 and 12."
                continue
            fi

            # Check the day based on the month
            if (( day < 1 || day > 31 )); then
                print_color "1;31" "Invalid Day! Must be between 01 and 31."
                continue
            fi

            # Check for months with 30 days: April, June, September, November
            if [[ "$month" == "04" || "$month" == "06" || "$month" == "09" || "$month" == "11" ]] && (( day > 30 )); then
                print_color "1;31" "Invalid Day! This month has only 30 days."
                continue
            fi

            # Check for February and leap years
            if [[ "$month" == "02" ]]; then
                if is_leap_year "$year"; then
                    # Leap year: February can have 29 days
                    if (( day > 29 )); then
                        print_color "1;31" "Invalid Day! February in a leap year can have at most 29 days."
                        continue
                    fi
                else
                    # Non-leap year: February can have at most 28 days
                    if (( day > 28 )); then
                        print_color "1;31" "Invalid Day! February can have at most 28 days in a non-leap year."
                        continue
                    fi
                fi
            fi
            
            # Check if hour is between 00 and 23
            if (( hour < 0 || hour > 23 )); then
                print_color "1;31" "Invalid Hour! Must be between 00 and 23."
                continue
            fi
            
            # Check if minute is between 00 and 59
            if (( minute < 0 || minute > 59 )); then
                print_color "1;31" "Invalid Minute! Must be between 00 and 59."
                continue
            fi

            # Check if the due date is in the future
            if check_overdue "$due"; then
                print_color "1;31" "The due date you entered is in the past. Please enter a future date."
            else
                break
            fi
        else
            print_color "1;31" "Invalid Date Format! Please use YYYY-MM-DD HH:MM"
        fi
    done
}

# Function to create a task
create_task () {
    print_color "1;33" "Enter Task Details"
    read -p "Enter Task: " name
    
    # Validate Due Date
    validate_due_date

    # Add task to file
    echo "False|$name|$due" >> $file
    print_color "1;32" "Task Created Successfully!"
    echo ""
}

# Function to check if the task is overdue
check_overdue() {
    local due_date=$1
    local current_date=$(date "+%Y-%m-%d+%H:%M")

    # Convert both dates to Unix timestamps for comparison
    local due_timestamp=$(date -d "$due_date" "+%s" 2>/dev/null)
    local current_timestamp=$(date "+%s")

    # Ensure due date conversion was successful
    if [ $? -ne 0 ]; then
        print_color "1;31" "Error in date format"
        return 1
    fi

    # Compare the timestamps
    if [ $due_timestamp -lt $current_timestamp ]; then
        return 0  # Task is overdue
    else
        return 1  # Task is not overdue
    fi
}

# Function to view completed tasks
view_completed () {
    print_color "1;32" "Completed Tasks:"
    echo "================"
    grep -i "True" "$file" | while IFS="|" read -r status task due; do
        print_color "1;32" "Task: $task"
        echo -e "Due: $due"
        echo -e "Status: Completed\n===================="
    done
}

# Function to view incomplete tasks
view_incomplete () {
    print_color "1;33" "Incomplete Tasks:"
    echo "=================="
    grep -i "False" "$file" | while IFS="|" read -r status task due; do
        print_color "1;33" "Task: $task"
        echo -e "Due: $due"

        # Check if task is overdue
        if check_overdue "$due"; then
            print_color "1;31" "This task is overdue!"
        fi
        echo -e "Status: Incomplete\n===================="
    done
}

# Function to search a task
search_task () {
    print_color "1;35" "Enter a task to search for:"
    read -p "Search Task: " task
    grep -i "$task" "$file" | while IFS="|" read -r status task due; do
        print_color "1;36" "Task: $task"
        print_color "1;36" "Due: $due"
        echo ""
    done
}

# Function to mark a task as completed
mark_completed() {
    print_color "1;34" "Enter the task number to mark as completed:"
    
    tasks=$(grep -n "False" "$file")
    if [ -z "$tasks" ]; then
        print_color "1;31" "No incomplete tasks found."
        return
    fi
    echo "$tasks"

    read -p "Enter the task number: " task_num
    task_line=$(sed -n "${task_num}p" "$file")

    if [ -z "$task_line" ]; then
        print_color "1;31" "Invalid task number."
        return
    fi

    task_name=$(echo "$task_line" | cut -d '|' -f 2)
    sed -i "${task_num}s|False|True|" "$file"
    print_color "1;32" "Task '$task_name' marked as completed!"
}

# Function to show help menu
show_help () {
    print_color "1;36" "1. Create a Task"
    print_color "1;36" "2. Show Completed Tasks"
    print_color "1;36" "3. Show Incomplete Tasks"
    print_color "1;36" "4. Search a Task"
    print_color "1;36" "5. Mark Task as Completed"
    print_color "1;36" "6. Show help"
    echo ""
}

# Menu Loop
show_help
while true; do
    echo
    read -p "Enter an option (1-6) (or press 'q' to quit): " a
    echo
    case $a in
        1) create_task ;;
        2) view_completed ;;
        3) view_incomplete ;;
        4) search_task ;;
        5) mark_completed ;;
        6) show_help ;;
        q) print_color "1;32" "Goodbye!" && exit 0 ;;
        *) print_color "1;31" "Invalid Option!" ;;
    esac
done
