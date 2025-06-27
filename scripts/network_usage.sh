#!/usr/bin/env bash

# This script calculates the network bandwidth usage and formats it for display in a tmux status bar.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

# --- Data Gathering Functions ---

# Fetches total received (RX) and transmitted (TX) bytes on Linux.
get_bytes_linux() {
    awk '/Inter|face|lo/ {next} {sum_rx += $2; sum_tx += $10} END {print sum_rx, sum_tx}' /proc/net/dev
}

# Fetches total received (RX) and transmitted (TX) bytes on macOS.
get_bytes_macos() {
    netstat -i -b | awk '/Name/{for(i=1;i<=NF;i++){if($i=="Ibytes"){rx_col=i}if($i=="Obytes"){tx_col=i}};next} /lo0/{next} {sum_rx+=$rx_col; sum_tx+=$tx_col} END {print sum_rx, sum_tx}'
}

# Formats a raw byte speed into a compact, human-readable string (e.g., 450K).
format_speed() {
    local speed=$1
    # Use si units (powers of 1000) and no decimal places for a compact status bar look.
    numfmt --to=si --suffix=B --format="%.0f" "$speed"
}


main() {
    # 1. Get the OLD state stored in tmux options.
    local old_time=$(get_tmux_option "@network_usage_old_time")
    local old_rx=$(get_tmux_option "@network_usage_old_rx")
    local old_tx=$(get_tmux_option "@network_usage_old_tx")

    # 2. Get the CURRENT state by reading network stats.
    local curr_time=$(date +%s)
    local os=$(uname)
    local curr_bytes
    if [[ "$os" == "Linux" ]]; then
        curr_bytes=( $(get_bytes_linux) )
    elif [[ "$os" == "Darwin" ]]; then
        curr_bytes=( $(get_bytes_macos) )
    else
        # Exit silently for unsupported OS.
        exit 0
    fi
    local curr_rx=${curr_bytes[0]}
    local curr_tx=${curr_bytes[1]}

    # 3. Handle the first run or invalid state.
    if [ -z "$old_time" ] || [ -z "$old_rx" ]; then
        # Save current state for the next run.
        set_tmux_option "@network_usage_old_time" "$curr_time"
        set_tmux_option "@network_usage_old_rx" "$curr_rx"
        set_tmux_option "@network_usage_old_tx" "$curr_tx"
        # Display a loading message until the next interval.
        echo -n "Loading..."
        exit 0
    fi

    # 4. Calculate speed.
    local time_diff=$((curr_time - old_time))
    
    # Avoid division by zero and handle system clock changes.
    if [ "$time_diff" -le 0 ]; then
        local last_value=$(get_tmux_option "@network_usage_last_value")
        echo -n "${last_value:-...}" # Show last known value or a placeholder.
        exit 0
    fi
    
    local rx_speed=$(((curr_rx - old_rx) / time_diff))
    local tx_speed=$(((curr_tx - old_tx) / time_diff))
    
    # Ensure speeds are not negative (can happen if counters reset, e.g. on reboot).
    [[ $rx_speed -lt 0 ]] && rx_speed=0
    [[ $tx_speed -lt 0 ]] && tx_speed=0

    local formatted_output="↓$(format_speed $rx_speed) • ↑$(format_speed $tx_speed)"
    set_tmux_option "@network_usage_last_value" "$formatted_output"

    # 6. Save the CURRENT state for the NEXT run.
    set_tmux_option "@network_usage_old_time" "$curr_time"
    set_tmux_option "@network_usage_old_rx" "$curr_rx"
    set_tmux_option "@network_usage_old_tx" "$curr_tx"

    # 7. Print the final result for the status bar.
    echo -n "$formatted_output"
}

# Execute the main function
main
