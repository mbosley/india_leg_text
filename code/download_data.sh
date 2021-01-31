#!/usr/bin/env bash
set -euo pipefail

# Downloads pdfs robustly. If download returns a too-small file
# size (in bytes), it deletes the file and tries again until
# 'max_attempts' is reached.

success=0
min_file_size=1000
max_attempts=10
i=1

echo "Links Location: $1"
echo "Keyword to Search: $2"
echo "Target Location: $3"

while [ $success = 0 ]
do
    cat "$1" | grep "$2" | xargs wget -O "$3"
    file_size=$(wc -c <"$3")
    if [ "$i" = $max_attempts ]; then
        echo "Maximum attempts reached, stopping"
        success=1
    elif [ "$file_size" -le $min_file_size ]; then
        echo "File size too small; removing and redownloading"
        rm -f "$3"
        i=$((i + 1))
    else
        echo "Download Successful"
	touch "$3"
        success=1
    fi
done
