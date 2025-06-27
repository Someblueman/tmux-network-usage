# tmux-network-usage

A tmux plugin that displays real-time network bandwidth usage in your status bar.

## What it does

Shows download and upload speeds in a compact format: `↓450kB • ↑200kB`

## Installation

### With Tmux Plugin Manager (TPM)

Add to your `.tmux.conf`:
```bash
set -g @plugin 'yourusername/tmux-network-usage'
```

Then press `prefix + I` to install.

### Manual Installation

Clone the repo:
```bash
git clone https://github.com/yourusername/tmux-network-usage ~/.tmux/plugins/tmux-network-usage
```

Add to your `.tmux.conf`:
```bash
run-shell ~/.tmux/plugins/tmux-network-usage/network_usage.tmux
```

## Usage

Add `#{network_usage}` to your status-right or status-left:
```bash
set -g status-right '#{network_usage} | %H:%M'
```

## Requirements

- macOS or Linux
- `numfmt` command (part of GNU coreutils)
  - macOS: `brew install coreutils`
  - Linux: Usually pre-installed