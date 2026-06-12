#!/bin/bash

local_dir="/home/justice-reaper/.local/share/applications"
mkdir -p "$local_dir"

while read -r file; do
    if [[ "$file" != /* ]]; then
        file="/$file"
    fi

    name=$(basename "$file")
    local_file="$local_dir/$name"

    if [[ ! -f "$file" ]]; then
        rm -f "$local_file"
        continue
    fi

    if ( grep -qi "terminal=false" "$file" ) || ( ! grep -qi "terminal=" "$file" && grep -qi "type=application" "$file" ); then

        if grep -qi "^Name=.*\<\(rofi\|flameshot\)\>" "$file"; then
            continue
        fi

        if grep -qi "^Categories=.*TerminalEmulator" "$file"; then
            continue
        fi

        cp "$file" "$local_file"

        if grep -qi "^Exec=.*pkexec" "$local_file"; then
            if ! grep -qi '^Exec=sh -c ".*pkexec' "$local_file"; then
                sed -i 's/^Exec=\(.*pkexec.*\)/Exec=sh -c "\1"/' "$local_file"
            fi
        fi

        chown justice-reaper:justice-reaper "$local_file"
    fi
done
