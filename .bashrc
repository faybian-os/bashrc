#!/bin/bash
# File_Rel_Path: 'filesystemRoot/home/user/bashrc'
# File_Type: '.sh'
# Squash_Source: 'c3c94ba38425135a53c45b7512332b37321a8eda'
ALSH_VERSION="beta-0.45.06"
TEXTC_DIRECTORY="$HOME/.alfe.sh/FaybianScripts/utils" # todo symlink .alfe to .alfe.sh or something
export ALSH_VERSION

$TEXTC_DIRECTORY/textc.sh --color darkred --text "AlSH Version:"
echo "$ALSH_VERSION"
echo ""
echo "----------"

# Use fastfetch if installed, else neofetch (if that is installed).
if command -v fastfetch &>/dev/null; then
    fastfetch --logo none
elif command -v neofetch &>/dev/null; then
    neofetch --ascii_distro "none"
fi

case $- in
    *i*) ;;
      *) return;;
esac

# Environment variables
HOST_ALIAS="x1"
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
HISTTIMEFORMAT="%F %I:%M:%S %p "
export VIRTUAL_ENV_DISABLE_PROMPT=1
# Force English (US) locale for time so %I/%p give 12-hour with AM/PM
export LC_TIME=en_US.UTF-8

# Shell options
shopt -s histappend
shopt -s checkwinsize
# Automatically cd into directory names (handles “config/” case)
shopt -s autocd

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# Function to get the Git prompt info - more efficiently
git_prompt_info() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return
    fi

    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    local color status_output timestamp hash
    timestamp=$(git show -s --format=%cd --date=format-local:'%m/%d/%y %I:%M %p' HEAD 2>/dev/null)
    hash=$(git rev-parse --short HEAD 2>/dev/null)
    status_output=$(git status --porcelain 2>/dev/null)

    if [ -z "$status_output" ] && git status | grep -q "Your branch is up to date with"; then
        color="\[\033[32m\]"  # Green – no bold
        echo "${color}($hash, $branch, clean, $timestamp)\[\033[00m\]"
    else
        color="\[\033[33m\]"  # Yellow/Orange – no bold
        local num_changes=$(echo "$status_output" | wc -l | tr -d ' ')
        echo "${color}($hash, $branch, ${num_changes} changes, $timestamp)\[\033[00m\]"
    fi
}

if [ "$color_prompt" = yes ]; then
    # Timestamp and version in grey, non-bold
    PS1="\[\033[90m\]\$(LC_TIME=en_US.UTF-8 date '+%m/%d/%y %I:%M:%S %p') AlSH $ALSH_VERSION\[\033[00m\] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@$HOST_ALIAS$(git_prompt_info)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
else
    PS1="\$(LC_TIME=en_US.UTF-8 date '+%m/%d/%y %I:%M:%S %p') AlSH $ALSH_VERSION ${debian_chroot:+($debian_chroot)}\u@$HOST_ALIAS$(git_prompt_info):\w\$ "
fi
unset color_prompt force_color_prompt

case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@$HOST_ALIAS: \w\a\]$PS1"
        ;;
    *)
        ;;
esac

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Enhanced cd command with logging
cd() {
    local old_cwd="$PWD"
    builtin cd "$@" && pwd && ls
    local new_cwd="$PWD"

    local timestamp=$(date +%s%3N)  # Milliseconds since epoch
    local pid="$$"
    local user="$USER"

    local log_dir="$HOME/.alfe.sh/alsh/dir_history/$pid"
    mkdir -p "$log_dir"

    local log_file="$log_dir/${timestamp}.json"

    # Escape special characters in old_cwd and new_cwd
    local escaped_old_cwd=$(printf '%s' "$old_cwd" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\n/\\n/g' -e 's/\r/\\r/g')
    local escaped_new_cwd=$(printf '%s' "$new_cwd" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\n/\\n/g' -e 's/\r/\\r/g')
    local cd_command="cd $*"
    local escaped_cd_command=$(printf '%s' "$cd_command" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\n/\\n/g' -e 's/\r/\\r/g')

    # Write the JSON
    cat > "$log_file" <<EOF
{
    "timestamp": "$timestamp",
    "pid": "$pid",
    "user": "$user",
    "old_cwd": "$escaped_old_cwd",
    "new_cwd": "$escaped_new_cwd",
    "cd_command": "$escaped_cd_command"
}
EOF
}

# Updated alias to use nano directly
alias n='nano'

echo "-------------"
$TEXTC_DIRECTORY/textc.sh --color darkred --text "Language Versions:"
echo "Node.js version: $(node -v)"
echo ""

# Improved filesystem display function
d() {
    echo "-------------"
    $TEXTC_DIRECTORY/textc.sh --color darkred --text "Filesystem:"
    echo "Filesystem      Size  Used Avail Use% Mounted on"
    # Only show the / mount and mounts starting with /mnt
    df -h | awk 'NR>1 && ($NF=="/" || $NF ~ /^\/mnt/)'
    echo ""

    echo "-------------"
    $TEXTC_DIRECTORY/textc.sh --color darkred --text "Screens:"
    screen -list
    echo ""
}
d

# Project directory info
pd() {
    echo "-------------"
    $TEXTC_DIRECTORY/textc.sh --color darkred --text "Git Status:"
    git status
    echo ""
    git log -n 3 --pretty=format:'%H %ai %an <%ae> %s' --abbrev-commit
    echo ""
    git remote -v
    echo ""
    echo "-------------"
    $TEXTC_DIRECTORY/textc.sh --color darkred --text "Current Directory:"
    pwd
    echo "-------------"
}
pd

# Define the git function and export it before calling exec_stage
git() {
    # Fast-push helpers
    if [ "$1" == "fpush" ] || [ "$1" == "fp" ] || [ "$1" == "f" ]; then
        shift
        ~/.fayra/Whimsical/git/faybian-git_reset/git_fpush.sh "$@"
        return
    fi

    # Quick status colourised
    if [ "$1" == "s" ] || [ "$1" == "status" ]; then
        shift
        sh -c "git status $*" | sed -e '/nothing to commit, working tree clean/ s/.*/\x1b[32m&\x1b[0m/'
        return
    fi

    # Remove any -v flag (or 'v' embedded inside grouped flags) for `git rm`
    if [ "$1" == "rm" ]; then
        shift
        local new_args=()
        for arg in "$@"; do
            # Skip stand-alone -v / --verbose
            if [ "$arg" == "-v" ] || [ "$arg" == "--verbose" ]; then
                continue
            fi
            # Strip 'v' from grouped short options (e.g. -rfv -> -rf)
            if [[ "$arg" == -* && "$arg" == *v* ]]; then
                local filtered="${arg//v/}"
                # If result is just '-' then ignore
                if [ "$filtered" == "-" ]; then
                    continue
                fi
                new_args+=("$filtered")
            else
                new_args+=("$arg")
            fi
        done
        command git rm "${new_args[@]}"
        return
    fi

    # Fallback – call git untouched
    command git "$@"
}
export -f git

alias gitf='git f'

history() {
    ~/.alfe.sh/alsh/history_reader.sh "$@"
}
export -f history

dir_history() {
    ~/.alfe.sh/alsh/dir_history.sh "$@"
}
export -f dir_history

# Navigation shortcuts
back() {
    # Navigate to the previous directory using dir_history
    local last_dir=$(~/.alfe.sh/alsh/dir_history.sh -n 2 | tail -n 1 | awk '{for(i=4;i<=NF;++i)printf "%s ",$i; print ""}' | sed 's/[[:space:]]*$//')
    if [ -n "$last_dir" ] && [ -d "$last_dir" ]; then
        cd "$last_dir"
    else
        echo "No previous directory found."
    fi
}
alias cdp='back'
alias cdb='back'
alias b='back'

# Window title management
update_window_title() {
    local home="${HOME%/}"

    if [[ "$PWD" == "$home" ]]; then
        SHORT_PWD="~"
    elif [[ "$PWD" == "$home/"* ]]; then
        SHORT_PWD="~/${PWD#$home/}"
    else
        SHORT_PWD="$PWD"
    fi

    TITLE="$USER@$HOSTNAME:${SHORT_PWD}$"
    # Timestamp and version set to grey
    PS1="${VIRTUAL_ENV_PROMPT}${debian_chroot:+($debian_chroot)}\[\033[90m\]\$(LC_TIME=en_US.UTF-8 date '+%m/%d/%y %I:%M:%S %p') AlSH $ALSH_VERSION\[\033[00m\] \[\033[01;32m\]\u@$HOST_ALIAS$(git_prompt_info)\[\033[00m\]:\[\033[01;34m\]${SHORT_PWD}\[\033[00m\]\$ "

    if [[ -n "$TITLE_OVERRIDE" ]]; then
        TITLE="$TITLE_OVERRIDE"
    fi

    echo -ne "\033]0;$TITLE\007"
}

set_title() {
    TITLE_OVERRIDE="$*"
    update_window_title
}

PROMPT_COMMAND="update_window_title"

update_window_title

# Shell environment aliases
alias cb='function _cb() { clear && bash; }; _cb'
alias c='clear'
alias cl='clear'
alias clr='clear'
alias cv='function _cv() { clear; n; gpt_print; }; _cv'
alias cx='chmod +x'
alias kdirstat='qdirstat'

# Directory and filesystem shortcuts
alias cgit='cd ~/.alfe.sh/git'
alias cdgit='cd ~/.alfe.sh/git'
alias lsl='ls -lahtr --group-directories-first --color=auto'
alias lsf='ls -lahtr --color=always | grep --color=always -v "^d"'

# Image-description helper aliases
alias imagedesc="$HOME/git/imgs_db/imagedesc.sh"
alias imgdesc="$HOME/git/imgs_db/imagedesc.sh"
alias imaged="$HOME/git/imgs_db/imagedesc.sh"
alias imgd="$HOME/git/imgs_db/imagedesc.sh"
alias rmbg="$HOME/git/logistica-remove_image_bg/run.sh" #/mnt/part5/dot_fayra/Whimsical/git/logistica-remove_image_bg

# ------------------------------------------------------------------
#  Bashrc updater
# ------------------------------------------------------------------
bashup() {
    cp /mnt/part5/dot_fayra/Whimsical/git/faybian-scripts-04092025/filesystemRoot/home/user/bashrc ~/.bashrc && \
        echo "Copied project bashrc to ~/.bashrc"
}
export -f bashup
alias bup='bashup'

alias alsh='bash'
alias bashrc='bash'

# Redshift function
rs() {
    local last_temp_file="$HOME/.fayra/redshift_last_temp"

    if [ -n "$1" ]; then
        LAST_RS_TEMP="$1"
        mkdir -p "$(dirname "$last_temp_file")"
        echo "$LAST_RS_TEMP" > "$last_temp_file"
        redshift -x
        redshift -O "$LAST_RS_TEMP"
        echo "Set Redshift color temp to: $LAST_RS_TEMP K"
    else
        if [ -f "$last_temp_file" ]; then
            LAST_RS_TEMP="$(cat "$last_temp_file")"
            echo "Redshift currently set to: $LAST_RS_TEMP K"
        else
            echo "No Redshift color temp has been set yet."
        fi
    fi
}
export -f rs

symlink() {
    if [ "$#" -ne 2 ]; then
        echo "Usage: symlink <target> <linkName>"
        return 1
    fi
    ln -s "$1" "$2"
}
export -f symlink

rmn() {
    if [ "$#" -eq 0 ]; then
        echo "Usage: rmn <filename>"
    else
        rm "$1" && nano "$1"
    fi
}

alias rnm='rmn'
alias nrm='rmn'
alias e='exit'
alias gf='git f'

# If bat is missing but batcat is present, alias bat to batcat
if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
    alias bat='batcat'
fi

alias cat='bat --paging=never --style=plain -l json'
alias ll='lsl'
alias gits='git s'
alias gs='git s'
alias clsl='clear && lsl'
alias gecko='okular'
alias gp='git pull'
alias gl='git log -n 3'

# ------------------------------------------------------------------
#  Auto-cat for non-executable files
# ------------------------------------------------------------------
command_not_found_handle() {
    local cmd="$1"
    # Only act if a regular readable, NON-executable file exists in CWD
    if [ -f "./$cmd" ] && [ ! -x "./$cmd" ] && [ -r "./$cmd" ]; then
        cat "./$cmd"
        return 0
    fi

    # Fallback to system handler if present
    if command -v command-not-found >/dev/null 2>&1; then
        command-not-found -- "$cmd"
    else
        echo "$cmd: command not found"
    fi
    return 127
}
export PATH="/home/syl/.pixi/bin:$PATH"
