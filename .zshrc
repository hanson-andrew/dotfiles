#source ~/powerlevel10k/powerlevel10k.zsh-theme

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
#if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
#fi

# Path to your oh-my-zsh installation.
#export ZSH="$HOME/.oh-my-zsh"

export EDITOR=nvim
export DOTFILES_REPO_URL=https://github.com/hanson-andrew/dotfiles.git
export PATH="$HOME/.devcontainers/bin:$PATH"
export PATH="$PATH:/opt/nvim/"
export PATH="$HOME/.local/bin:$PATH"
export LANG=en_US.UTF-8


if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

unsetopt BEEP
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME -c status.showUntrackedFiles=no'

###-begin-npm-completion-###
#
# npm command completion script
#
# Installation: npm completion >> ~/.bashrc  (or ~/.zshrc)
# Or, maybe: npm completion > /usr/local/etc/bash_completion.d/npm
#

if type complete &>/dev/null; then
  _npm_completion () {
    local words cword
    if type _get_comp_words_by_ref &>/dev/null; then
      _get_comp_words_by_ref -n = -n @ -n : -w words -i cword
    else
      cword="$COMP_CWORD"
      words=("${COMP_WORDS[@]}")
    fi

    local si="$IFS"
    if ! IFS=$'\n' COMPREPLY=($(COMP_CWORD="$cword" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           npm completion -- "${words[@]}" \
                           2>/dev/null)); then
      local ret=$?
      IFS="$si"
      return $ret
    fi
    IFS="$si"
    if type __ltrim_colon_completions &>/dev/null; then
      __ltrim_colon_completions "${words[cword]}"
    fi
  }
  complete -o default -F _npm_completion npm
elif type compdef &>/dev/null; then
  _npm_completion() {
    local si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 npm completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef _npm_completion npm
elif type compctl &>/dev/null; then
  _npm_completion () {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    if ! IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       npm completion -- "${words[@]}" \
                       2>/dev/null)); then

      local ret=$?
      IFS="$si"
      return $ret
    fi
    IFS="$si"
  }
  compctl -K _npm_completion npm
fi
###-end-npm-completion-###

export TMUX_DEFAULT_SHELL="$(command -v zsh)"


### start devcontainer-cli-support ###

_dc_devcontainer_name() {
  devcontainer read-configuration --workspace-folder . 2>/dev/null \
    | jq -r '.configuration.name // empty'
}


# ----------------------------
# git-credential-domain-socket-forwarder
# ----------------------------

DC_GCF_HOST_EXE="dcgw"
DC_GCF_CONTAINER_EXE="/usr/local/bin/git-credential-domain-socket-forwarder"
DC_GCF_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/git-credential-domain-socket-forwarder"
DC_GCF_SOCKET="$DC_GCF_STATE_DIR/git-credential-forwarder.sock"
DC_GCF_CONTAINER_STATE_DIR="/mnt/git-credential-forwarder"
DC_GCF_CONTAINER_SOCKET="$DC_GCF_CONTAINER_STATE_DIR/git-credential-forwarder.sock"

_dc_gcf_server_addr() {
  printf '%s\n' "$DC_GCF_CONTAINER_SOCKET"
}

_dc_resolve_exe() {
  local name_or_path="$1"
  local resolved

  resolved="$(command -v -- "$name_or_path")" || {
    echo "Could not find executable: $name_or_path" >&2
    return 1
  }

  # Optional but useful: turn symlinks/relative paths into an absolute path.
  # macOS may not have GNU readlink -f, so prefer realpath if available.
  if command -v realpath >/dev/null 2>&1; then
    realpath "$resolved"
  else
    echo "$resolved"
  fi
}

_dc_ensure_gcf_host() {
  mkdir -p "$DC_GCF_STATE_DIR"

  if ! command -v "$DC_GCF_HOST_EXE" >/dev/null 2>&1; then
    echo "Git credential socket forwarder executable not at $DC_GCF_HOST_EXE found or not executable: $DC_GCF_HOST_EXE" >&2
    return 1
  fi

  # If socket exists and server appears alive, we're done.
  if [[ -S "$DC_GCF_SOCKET" ]]; then
    if command -v fuser >/dev/null 2>&1 && fuser "$DC_GCF_SOCKET" >/dev/null 2>&1; then
      return 0
    fi

    if command -v lsof >/dev/null 2>&1 && lsof "$DC_GCF_SOCKET" >/dev/null 2>&1; then
      return 0
    fi

    rm -f "$DC_GCF_SOCKET"
  fi

  echo "Starting git credential socket forwarder at $DC_GCF_SOCKET..."
  nohup "$DC_GCF_HOST_EXE" server --socket "$DC_GCF_SOCKET" \
    >"$DC_GCF_STATE_DIR/server.log" 2>&1 < /dev/null &

  echo $! > "$DC_GCF_STATE_DIR/server.pid"

  sleep 1

  if [[ ! -S "$DC_GCF_SOCKET" ]]; then
    echo "Credential socket forwarder did not start; see $DC_GCF_STATE_DIR/server.log" >&2
    return 1
  fi
}

_dc_bootstrap_gcf_container() {
  local host_gitconfig="$HOME/.gitconfig"
  local server_addr
  server_addr="$(_dc_gcf_server_addr)"

  if [[ ! -f "$host_gitconfig" ]]; then
    echo "Host ~/.gitconfig not found; skipping container gitconfig sync" >&2
    return 0
  fi

  devcontainer exec --workspace-folder . bash -lc 'mkdir -p "$HOME"' || return 1
  devcontainer exec --workspace-folder . sh -lc 'cat > "$HOME/.gitconfig.host"' < "$host_gitconfig" || return 1

  devcontainer exec \
    --workspace-folder . \
    --remote-env GIT_CREDENTIAL_FORWARDER_SOCKET="$server_addr" \
    --remote-env DC_GCF_CONTAINER_EXE="$DC_GCF_CONTAINER_EXE" \
    bash -lc '
      set -euo pipefail

      if [[ ! -x "$DC_GCF_CONTAINER_EXE" ]]; then
        echo "Credential forwarder client not mounted at $DC_GCF_CONTAINER_EXE" >&2
        exit 1
      fi

      git config --file "$HOME/.gitconfig.host" --unset-all credential.helper || true

      if ! git config --global --get-all include.path | grep -Fx "$HOME/.gitconfig.host" >/dev/null 2>&1; then
        git config --global --add include.path "$HOME/.gitconfig.host"
      fi

      git config --global --unset-all credential.helper || true
      git config --global credential.helper \
        "!f(){ $DC_GCF_CONTAINER_EXE client \"\$@\" --socket \"\${GIT_CREDENTIAL_FORWARDER_SOCKET}\"; }; f"
   '
}

dcexec() {
  local server_addr
  server_addr="$(_dc_gcf_server_addr)"

  _dc_ensure_gcf_host || return 1
  _dc_bootstrap_gcf_container || return 1

  devcontainer exec \
    --workspace-folder . \
    --remote-env GIT_CREDENTIAL_FORWARDER_SOCKET="$server_addr" \
    "$@"
}

dcup() {
  local host_exe="${DC_GCF_HOST_EXE:-dcgw}"
  local host_exe_path

  host_exe_path="$(_dc_resolve_exe "$host_exe")" || return 1

  devcontainer up --workspace-folder . \
    --mount "type=bind,source=$DC_GCF_STATE_DIR,target=$DC_GCF_CONTAINER_STATE_DIR" \
    --mount "type=bind,source=$host_exe_path,target=$DC_GCF_CONTAINER_EXE"
}

_dc_devcontainer_id() {
  docker ps -aq \
    --filter "label=devcontainer.local_folder=$PWD" \
    --format '{{.ID}}' \
    | head -n 1
}

dcstop() {
  local container_id
  container_id="$(_dc_devcontainer_id)"

  if [[ -z "$container_id" ]]; then
    echo "No devcontainer found for workspace folder: $PWD" >&2
    return 1
  fi

  docker stop "$container_id"
}

dcdown() {
  local container_id
  container_id="$(_dc_devcontainer_id)"

  if [[ -z "$container_id" ]]; then
    echo "No devcontainer found for workspace folder: $PWD" >&2
    return 1
  fi

  docker stop "$container_id" >/dev/null 2>&1 || true
  docker rm "$container_id"
}

dcdot() {
  : "${DOTFILES_REPO_URL:?DOTFILES_REPO_URL is not set}"
  local server_addr
  server_addr="$(_dc_gcf_server_addr)"

  devcontainer exec --workspace-folder . \
    --remote-env GIT_CREDENTIAL_FORWARDER_SOCKET="$server_addr" \
    bash -lc '
    set -e

    stamp="$HOME/.dotfiles-bootstrap-done"

    if [ ! -d "$HOME/.dotfiles" ]; then
      git clone --bare "'"$DOTFILES_REPO_URL"'" "$HOME/.dotfiles"
      git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
      git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" fetch origin
      git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" branch --set-upstream-to=origin/main main
    fi

    if [ ! -f "$stamp" ]; then
      rm -f "$HOME/.zshrc" "$HOME/.p10k.zsh" "$HOME/.vimrc"

      git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout -f

      if [ -x "$HOME/.bootstrap/linux/bootstrap-ubuntu.sh" ]; then
        "$HOME/.bootstrap/linux/bootstrap-ubuntu.sh"
      elif [ -f "$HOME/.bootstrap/linux/bootstrap-ubuntu.sh" ]; then
        sh "$HOME/.bootstrap/linux/bootstrap-ubuntu.sh"
      else
        echo "Expected $HOME/.bootstrap/linux/bootstrap-ubuntu.sh but it was not found" >&2
        exit 1
      fi

      if [ ! -d "$HOME/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
      fi

      touch "$stamp"
    fi
  '
}

dcshell() {
  local dc_name
  local server_addr

  dc_name="$(_dc_devcontainer_name)"
  [[ -z "$dc_name" ]] && dc_name="devcontainer"

  server_addr=$(_dc_gcf_server_addr)

  _dc_ensure_gcf_host || return 1
  _dc_bootstrap_gcf_container || return 1
  dcdot || return 1

  clear
  devcontainer exec \
    --workspace-folder . \
    --remote-env TERM=xterm-256color \
    --remote-env DEVCONTAINER_TAB_TITLE="$dc_name" \
    --remote-env GIT_CREDENTIAL_FORWARDER_SOCKET="$server_addr" \
    zsh -l
}

function _set_context_title() {
  local context=""
  local title=""

  if [[ -n "$DEVCONTAINER_TAB_TITLE" ]]; then
    context="dc"
    title="$DEVCONTAINER_TAB_TITLE"
  else
    context="host"
    title="${HOST:-$(hostname)}"
  fi

  print -Pn "\e]0;[${context}] ${title}\a"
}

precmd_functions+=(_set_context_title)
_set_context_title

## end devcontainer-cli-support ##


merge_claude_settings() {
  local base="$HOME/.claude/settings.json"
  local override="$HOME/.claude-settings.json"

  # Only run if override exists
  if [[ -f "$override" ]]; then
    # Ensure base exists (create empty JSON if not)
    if [[ ! -f "$base" ]]; then
      mkdir -p "$(dirname "$base")"
      echo '{}' > "$base"
    fi

    # Merge: override wins at top level
    tmp="$(mktemp)"
    jq -s '.[0] + .[1]' "$base" "$override" > "$tmp" && mv "$tmp" "$base"
  fi
}

# Run it (optional: comment out if you only want it manually)
merge_claude_settings


function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	command rm -f -- "$tmp"
}

eval "$(starship init zsh)"
