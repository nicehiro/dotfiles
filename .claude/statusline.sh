#!/bin/bash
# Starship-inspired statusLine for Claude Code
# Read JSON input from stdin
input=$(cat)

# Extract values using jq
MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir')

# Build status components
components=()

# Directory component (show relative to home if applicable)
DIR_DISPLAY="${CURRENT_DIR/#$HOME/~}"
if [ "$CURRENT_DIR" != "$PROJECT_DIR" ] && [ -n "$PROJECT_DIR" ]; then
    # Show path relative to project root
    REL_PATH="${CURRENT_DIR#$PROJECT_DIR/}"
    components+=("$(basename "$PROJECT_DIR")/$REL_PATH")
else
    components+=("$(basename "$CURRENT_DIR")")
fi

# Git component with status (using --no-optional-locks to avoid lock conflicts)
if git --git-dir="$CURRENT_DIR/.git" --work-tree="$CURRENT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git --git-dir="$CURRENT_DIR/.git" --work-tree="$CURRENT_DIR" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -z "$BRANCH" ]; then
        BRANCH=$(git --git-dir="$CURRENT_DIR/.git" --work-tree="$CURRENT_DIR" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    fi

    if [ -n "$BRANCH" ]; then
        # Check git status for modifications (skip optional locks)
        GIT_STATUS=$(git --git-dir="$CURRENT_DIR/.git" --work-tree="$CURRENT_DIR" --no-optional-locks status --porcelain 2>/dev/null)

        if [ -n "$GIT_STATUS" ]; then
            # Count changes
            MODIFIED=$(echo "$GIT_STATUS" | grep -c "^ M" 2>/dev/null || echo "0")
            ADDED=$(echo "$GIT_STATUS" | grep -c "^A" 2>/dev/null || echo "0")
            UNTRACKED=$(echo "$GIT_STATUS" | grep -c "^??" 2>/dev/null || echo "0")

            STATUS_INDICATOR=""
            [ "$MODIFIED" -gt 0 ] && STATUS_INDICATOR="${STATUS_INDICATOR}*"
            [ "$ADDED" -gt 0 ] && STATUS_INDICATOR="${STATUS_INDICATOR}+"
            [ "$UNTRACKED" -gt 0 ] && STATUS_INDICATOR="${STATUS_INDICATOR}?"

            components+=("$BRANCH$STATUS_INDICATOR")
        else
            components+=("$BRANCH")
        fi
    fi
fi

# Python environment detection
if [ -f "$CURRENT_DIR/pyproject.toml" ] || [ -f "$CURRENT_DIR/requirements.txt" ] || [ -f "$CURRENT_DIR/setup.py" ]; then
    if [ -n "$VIRTUAL_ENV" ]; then
        VENV_NAME=$(basename "$VIRTUAL_ENV")
        components+=("$VENV_NAME")
    fi
fi

# Node.js environment detection
if [ -f "$CURRENT_DIR/package.json" ]; then
    NODE_VERSION=$(node -v 2>/dev/null)
    [ -n "$NODE_VERSION" ] && components+=("node $NODE_VERSION")
fi

# Context window usage
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')

    # Only calculate if size is valid (not 0 or null)
    if [ "$size" != "null" ] && [ "$size" -gt 0 ] 2>/dev/null; then
        pct=$((current * 100 / size))

        # Only show if >5% usage
        if [ "$pct" -gt 5 ]; then
            components+=("${pct}% ctx")
        fi
    fi
fi

# Join components with separator
status=""
for i in "${!components[@]}"; do
    if [ $i -eq 0 ]; then
        status="${components[$i]}"
    else
        status="$status | ${components[$i]}"
    fi
done

# Output with model name
printf '%s | %s' "$MODEL_DISPLAY" "$status"
