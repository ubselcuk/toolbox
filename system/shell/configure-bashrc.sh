#!/usr/bin/env bash
. "$(dirname "$0")/../../lib/common.sh"

configure_bashrc() {
  local TARGET="$HOME/.bashrc"
  [[ -f "$TARGET" ]] || touch "$TARGET"
  info "Configuring bashrc: $TARGET"

  # Lines to add
  local LINES=(
    "alias ..='cd ..'"
    "alias ...='cd ../..'"
    "alias ....='cd ../../..'"
    "HISTCONTROL=ignoredups:erasedups"
    "HISTSIZE=50000"
    "HISTFILESIZE=100000"
    "shopt -s histappend"
    "PROMPT_COMMAND=\"history -a; history -n\""
    "export PROMPT_DIRTRIM=2"
    "PS1='\\[\\033[1;32m\\]\\u@\\h \\[\\033[1;34m\\]\\w\\[\\033[0m\\] \\$ '"
  )

  for LINE in "${LINES[@]}"; do
    local KEY=${LINE%%=*}    # Part before "=" (e.g., alias .., HISTSIZE)
    local NEW_VAL=${LINE#*=} # Part after "="

    # 1) Exact line already exists
    if grep -Fxq "$LINE" "$TARGET"; then
      info "[skip] $LINE"
      continue
    fi

    # 2) Same key exists but with a different value
    local EXISTING
    if EXISTING=$(grep -E "^\s*${KEY}=" "$TARGET" | head -n1); then
      local OLD_VAL=${EXISTING#*=}
      if [[ "$OLD_VAL" == "$NEW_VAL" ]]; then
        info "[skip] $LINE"
      else
        warn "$KEY is already defined with a different value (old=$OLD_VAL, new=$NEW_VAL). Not overwriting."
      fi
      continue
    fi

    # 3) Not found — add it
    printf '%s\n' "$LINE" >>"$TARGET"
    info "[add]  $LINE"
  done

  info "bashrc configuration completed (will take effect in a new session or after 'source ~/.bashrc')."
}

configure_bashrc
