#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# This runs when the plugin is loaded
main() {
    # Get current status-right and status-left
    local status_right=$(tmux show-option -gqv status-right)
    local status_left=$(tmux show-option -gqv status-left)
    
    # Replace #{network_usage} with the actual script call
    local network_usage_script="#($CURRENT_DIR/scripts/network_usage.sh)"
    
    # Update status-right if it contains #{network_usage}
    if [[ "$status_right" == *"#{network_usage}"* ]]; then
        status_right="${status_right//\#\{network_usage\}/$network_usage_script}"
        tmux set-option -gq status-right "$status_right"
    fi
    
    # Update status-left if it contains #{network_usage}
    if [[ "$status_left" == *"#{network_usage}"* ]]; then
        status_left="${status_left//\#\{network_usage\}/$network_usage_script}"
        tmux set-option -gq status-left "$status_left"
    fi
}

main