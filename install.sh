#!/usr/bin/env sh
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
TMUX_CONFIG_DIR="$HOME/.config/tmux"
TPM_DIR="$TMUX_CONFIG_DIR/plugins/tpm"
LOCAL_BIN="$HOME/.local/bin"
BASHRC="$HOME/.bashrc"

# ==================================================
# Utility: ensure ~/.local/bin exists
# ==================================================
ensure_local_bin() {
  mkdir -p "$LOCAL_BIN"
}

# ==================================================
# Utility: idempotent line adder
# ==================================================
ensure_line() {
  file="$1"
  line="$2"
  touch "$file"
  if grep -qsF -- "$line" "$file"; then
    return 0
  fi
  echo "$line" >>"$file"
}

# ==================================================
# Task: Install / update tpm
# ==================================================
task_tpm() {
  echo "  [tpm] Installing tmux plugin manager..."
  if [ -d "$TPM_DIR" ]; then
    echo "    Updating existing tpm..."
    git -C "$TPM_DIR" pull --ff-only
  else
    echo "    Cloning tpm..."
    git clone https://github.com/RyanMacG/tpm-redux.git "$TPM_DIR"
  fi
  echo "  [tpm] Done."
}

# ==================================================
# Task: Deploy tmux config
# ==================================================
task_tmux_config() {
  echo "  [config] Deploying tmux config..."

  deploy_with_stow() {
    cd "$DOTFILES"
    stow -R --target="$HOME" .
  }

  deploy_with_ln() {
    mkdir -p "$TMUX_CONFIG_DIR"
    ln -sf "$DOTFILES/.config/tmux/tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
    ln -sf "$DOTFILES/.config/tmux/catppuccin.tmux.conf" "$TMUX_CONFIG_DIR/catppuccin.tmux.conf"
  }

  deploy_with_cp() {
    mkdir -p "$TMUX_CONFIG_DIR"
    cp "$DOTFILES/.config/tmux/tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
    cp "$DOTFILES/.config/tmux/catppuccin.tmux.conf" "$TMUX_CONFIG_DIR/catppuccin.tmux.conf"
  }

  if command -v stow >/dev/null 2>&1; then
    echo "    Using stow..."
    deploy_with_stow
  elif command -v ln >/dev/null 2>&1; then
    echo "    Creating symlinks..."
    deploy_with_ln
  else
    echo "    Copying files..."
    deploy_with_cp
  fi
  echo "  [config] Done."
}

# ==================================================
# Task: Install fzf binary + shell integration
# ==================================================
task_fzf() {
  echo "  [fzf] Installing..."

  # Binary
  ensure_local_bin
  if ! command -v fzf >/dev/null 2>&1; then
    echo "    Downloading latest fzf binary..."
    FZF_URL="https://github.com/junegunn/fzf/releases/latest/download/fzf-$(uname -s)_$(uname -m).tar.gz"
    curl -fsSL "$FZF_URL" | tar xz -C "$LOCAL_BIN"
    chmod +x "$LOCAL_BIN/fzf"
    echo "    Installed to $LOCAL_BIN/fzf"
  else
    echo "    Binary already installed at $(command -v fzf)"
  fi

  # Shell integration (bash)
  echo "    Adding shell integration to ~/.bashrc..."
  ensure_line "$BASHRC" 'eval "$(fzf --bash)"'

  echo "  [fzf] Done."
}

# ==================================================
# Task: Install zoxide binary + shell integration
# ==================================================
task_zoxide() {
  echo "  [zoxide] Installing..."

  # Binary
  ensure_local_bin
  if ! command -v zoxide >/dev/null 2>&1; then
    echo "    Downloading latest zoxide binary..."
    ARCH=$(uname -m)
    case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64) ARCH="aarch64" ;;
    *)
      echo "    Unsupported architecture: $ARCH"
      exit 1
      ;;
    esac
    ZOXIDE_URL="https://github.com/ajeetdsouza/zoxide/releases/latest/download/zoxide-${ARCH}-unknown-linux-musl"
    curl -fsSL "$ZOXIDE_URL" -o "$LOCAL_BIN/zoxide"
    chmod +x "$LOCAL_BIN/zoxide"
    echo "    Installed to $LOCAL_BIN/zoxide"
  else
    echo "    Binary already installed at $(command -v zoxide)"
  fi

  # Shell integration (bash)
  echo "    Adding shell integration to ~/.bashrc..."
  ensure_line "$BASHRC" 'eval "$(zoxide init bash --cmd cd)"'

  echo "  [zoxide] Done."
}

# ==================================================
# Task: Install sesh binary
# ==================================================
task_sesh() {
  echo "  [sesh] Installing..."

  ensure_local_bin
  if command -v sesh >/dev/null 2>&1; then
    echo "    Binary already installed at $(command -v sesh)"
    echo "  [sesh] Done."
    return
  fi

  echo "    Downloading latest sesh binary..."
  ARCH=$(uname -m)
  case "$ARCH" in
  x86_64) ARCH="x86_64" ;;
  aarch64) ARCH="arm64" ;;
  *)
    echo "    Unsupported architecture: $ARCH"
    exit 1
    ;;
  esac

  SESH_URL="https://github.com/joshmedeski/sesh/releases/latest/download/sesh_Linux_${ARCH}.tar.gz"
  curl -fsSL "$SESH_URL" | tar xz -C "$LOCAL_BIN" sesh
  chmod +x "$LOCAL_BIN/sesh"
  echo "    Installed to $LOCAL_BIN/sesh"
  echo "  [sesh] Done."
}

# ==================================================
# Task: Install tv (television) binary + shell integration
# ==================================================
task_tv() {
  echo "  [tv] Installing..."

  ensure_local_bin
  if ! command -v tv >/dev/null 2>&1; then
    echo "    Fetching latest tv release info..."
    ARCH=$(uname -m)
    case "$ARCH" in
    x86_64) TV_TARGET="x86_64-unknown-linux-musl" ;;
    aarch64) TV_TARGET="aarch64-unknown-linux-musl" ;;
    *)
      echo "    Unsupported architecture: $ARCH"
      exit 1
      ;;
    esac

    TV_URL=$(curl -fsSL https://api.github.com/repos/alexpasmantier/television/releases/latest |
      grep browser_download_url |
      grep "$TV_TARGET.tar.gz" |
      grep -v sha256 |
      head -1 |
      cut -d '"' -f 4)

    if [ -z "$TV_URL" ]; then
      echo "    Failed to find download URL"
      exit 1
    fi

    echo "    Downloading tv..."
    TMPDIR=$(mktemp -d)
    curl -fsSL "$TV_URL" | tar xz -C "$TMPDIR"
    find "$TMPDIR" -type f -name "tv" -exec mv {} "$LOCAL_BIN/tv" \;
    chmod +x "$LOCAL_BIN/tv"
    rm -rf "$TMPDIR"
    echo "    Installed to $LOCAL_BIN/tv"
  else
    echo "    Binary already installed at $(command -v tv)"
  fi

  # Shell integration (bash) — always run
  echo "    Adding shell integration to ~/.bashrc..."
  ensure_line "$BASHRC" 'eval "$(tv init bash)"'

  echo "  [tv] Done."
}

# ==================================================
# Task: Install fd binary
# ==================================================
task_fd() {
  echo "  [fd] Installing..."

  ensure_local_bin
  if command -v fd >/dev/null 2>&1; then
    echo "    Binary already installed at $(command -v fd)"
    echo "  [fd] Done."
    return
  fi

  echo "    Fetching latest fd release info..."
  ARCH=$(uname -m)
  case "$ARCH" in
  x86_64) FD_TARGET="x86_64-unknown-linux-musl" ;;
  aarch64) FD_TARGET="aarch64-unknown-linux-musl" ;;
  *)
    echo "    Unsupported architecture: $ARCH"
    exit 1
    ;;
  esac

  FD_URL=$(curl -fsSL https://api.github.com/repos/sharkdp/fd/releases/latest |
    grep browser_download_url |
    grep "$FD_TARGET.tar.gz" |
    head -1 |
    cut -d '"' -f 4)

  if [ -z "$FD_URL" ]; then
    echo "    Failed to find download URL"
    exit 1
  fi

  echo "    Downloading fd..."
  TMPDIR=$(mktemp -d)
  curl -fsSL "$FD_URL" | tar xz -C "$TMPDIR"
  find "$TMPDIR" -type f -name "fd" -exec mv {} "$LOCAL_BIN/fd" \;
  chmod +x "$LOCAL_BIN/fd"
  rm -rf "$TMPDIR"
  echo "    Installed to $LOCAL_BIN/fd"
  echo "  [fd] Done."
}

# ==================================================
# Task: Install yazi binary
# ==================================================
task_yazi() {
  echo "  [yazi] Installing..."

  ensure_local_bin
  if command -v yazi >/dev/null 2>&1; then
    echo "    Binary already installed at $(command -v yazi)"
    echo "  [yazi] Done."
    return
  fi

  echo "    Fetching latest yazi release info..."
  ARCH=$(uname -m)
  case "$ARCH" in
  x86_64) YAZI_TARGET="x86_64-unknown-linux-musl" ;;
  aarch64) YAZI_TARGET="aarch64-unknown-linux-musl" ;;
  *)
    echo "    Unsupported architecture: $ARCH"
    exit 1
    ;;
  esac

  YAZI_URL=$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest |
    grep browser_download_url |
    grep "$YAZI_TARGET.zip" |
    head -1 |
    cut -d '"' -f 4)

  if [ -z "$YAZI_URL" ]; then
    echo "    Failed to find download URL"
    exit 1
  fi

  echo "    Downloading yazi..."
  TMPDIR=$(mktemp -d)
  curl -fsSL "$YAZI_URL" -o "$TMPDIR/yazi.zip"
  unzip -qo "$TMPDIR/yazi.zip" -d "$TMPDIR"
  find "$TMPDIR" -type f -name "yazi" -exec mv {} "$LOCAL_BIN/yazi" \;
  find "$TMPDIR" -type f -name "ya" -exec mv {} "$LOCAL_BIN/ya" \;
  chmod +x "$LOCAL_BIN/yazi" "$LOCAL_BIN/ya"
  rm -rf "$TMPDIR"
  echo "    Installed to $LOCAL_BIN/yazi and $LOCAL_BIN/ya"
  echo "  [yazi] Done."
}

# ==================================================
# Task: Install atuin binary + shell integration
# ==================================================
task_atuin() {
  echo "  [atuin] Installing..."

  # Binary
  ensure_local_bin
  if ! command -v atuin >/dev/null 2>&1; then
    echo "    Downloading latest atuin binary..."
    ARCH=$(uname -m)
    case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64) ARCH="aarch64" ;;
    *)
      echo "    Unsupported architecture: $ARCH"
      exit 1
      ;;
    esac

    ATUIN_URL="https://github.com/atuinsh/atuin/releases/latest/download/atuin-${ARCH}-unknown-linux-gnu.tar.gz"
    curl -fsSL "$ATUIN_URL" | tar xz -C "$LOCAL_BIN" --strip-components=1
    chmod +x "$LOCAL_BIN/atuin"
    echo "    Installed to $LOCAL_BIN/atuin"
  else
    echo "    Binary already installed at $(command -v atuin)"
  fi

  # Shell integration (bash)
  echo "    Adding shell integration to ~/.bashrc..."
  ensure_line "$BASHRC" 'eval "$(atuin init bash)"'

  echo "  [atuin] Done."
}

# ==================================================
# Task: Install bash-preexec for atuin
# ==================================================
task_bash_preexec() {
  echo "  [bash-preexec] Installing..."

  BASH_PREEXEC_DIR="$HOME/.local/share/bash-preexec"
  if [ -f "$BASH_PREEXEC_DIR/bash-preexec.sh" ]; then
    echo "    bash-preexec already installed"
    echo "  [bash-preexec] Done."
    return
  fi

  echo "    Downloading bash-preexec 0.6.0..."
  mkdir -p "$BASH_PREEXEC_DIR"
  curl -fsSL "https://raw.githubusercontent.com/rcaloras/bash-preexec/0.6.0/bash-preexec.sh" -o "$BASH_PREEXEC_DIR/bash-preexec.sh"

  echo "    Adding bash-preexec to ~/.bashrc..."
  ensure_line "$BASHRC" 'source ~/.local/share/bash-preexec/bash-preexec.sh'

  echo "  [bash-preexec] Done."
}

# ==================================================
# Task: Deploy ghostty config
# ==================================================
task_ghostty() {
  echo "  [ghostty] Deploying ghostty config..."

  GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"

  deploy_g_stow() {
    cd "$DOTFILES"
    stow -R --target="$HOME" .
  }

  deploy_g_ln() {
    mkdir -p "$GHOSTTY_CONFIG_DIR"
    ln -sf "$DOTFILES/.config/ghostty/config" "$GHOSTTY_CONFIG_DIR/config"
    if [ -d "$DOTFILES/.config/ghostty/themes" ]; then
      mkdir -p "$GHOSTTY_CONFIG_DIR/themes"
      for theme_file in "$DOTFILES/.config/ghostty/themes/"*; do
        [ -f "$theme_file" ] && ln -sf "$theme_file" "$GHOSTTY_CONFIG_DIR/themes/"
      done
    fi
  }

  deploy_g_cp() {
    mkdir -p "$GHOSTTY_CONFIG_DIR"
    cp "$DOTFILES/.config/ghostty/config" "$GHOSTTY_CONFIG_DIR/config"
    if [ -d "$DOTFILES/.config/ghostty/themes" ]; then
      cp -r "$DOTFILES/.config/ghostty/themes/"* "$GHOSTTY_CONFIG_DIR/themes/"
    fi
  }

  if command -v stow >/dev/null 2>&1; then
    echo "    Using stow..."
    deploy_g_stow
  elif command -v ln >/dev/null 2>&1; then
    echo "    Creating symlinks..."
    deploy_g_ln
  else
    echo "    Copying files..."
    deploy_g_cp
  fi
  echo "  [ghostty] Done."
}

# ==================================================
# Task: Install ghostty app
# ==================================================
task_install_ghostty() {
  echo "  [ghostty-app] Installing ghostty..."
  if command -v ghostty >/dev/null 2>&1; then
    echo "    Ghostty already installed at $(command -v ghostty)"
    echo "  [ghostty-app] Done."
    return
  fi
  echo "    Running ghostty-ubuntu install script..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
  echo "  [ghostty-app] Done."
}

# ==================================================
# Task: Install Maple Mono Nerd Font
# ==================================================
task_maple_font() {
  echo "  [maple-font] Installing Maple Mono NF..."

  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  if ls "$FONT_DIR/MapleMono"*.ttf >/dev/null 2>&1; then
    echo "    Maple Mono NF already installed"
    echo "  [maple-font] Done."
    return
  fi

  echo "    Downloading Maple Mono NF..."
  FONT_URL="https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF-unhinted.zip"
  TMPDIR=$(mktemp -d)
  curl -fsSL "$FONT_URL" -o "$TMPDIR/MapleMono-NF-unhinted.zip"
  unzip -qo "$TMPDIR/MapleMono-NF-unhinted.zip" -d "$TMPDIR/fonts"
  find "$TMPDIR/fonts" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec mv {} "$FONT_DIR/" \;
  rm -rf "$TMPDIR"

  echo "    Updating font cache..."
  fc-cache -fv >/dev/null 2>&1
  echo "    Installed to $FONT_DIR"
  echo "  [maple-font] Done."
}

# ==================================================
# Task: Deploy nvim config
# ==================================================
task_nvim() {
  echo "  [nvim] Deploying nvim config..."

  NVIM_CONFIG_DIR="$HOME/.config/nvim"

  deploy_n_stow() {
    cd "$DOTFILES"
    stow -R --target="$HOME" .
  }

  deploy_n_ln() {
    mkdir -p "$NVIM_CONFIG_DIR/lua/plugins"
    ln -sf "$DOTFILES/.config/nvim/init.lua" "$NVIM_CONFIG_DIR/init.lua"
    ln -sf "$DOTFILES/.config/nvim/nvim-pack-lock.json" "$NVIM_CONFIG_DIR/nvim-pack-lock.json"
    for f in "$DOTFILES/.config/nvim/lua/plugins/"*.lua; do
      [ -f "$f" ] && ln -sf "$f" "$NVIM_CONFIG_DIR/lua/plugins/"
    done
  }

  deploy_n_cp() {
    mkdir -p "$NVIM_CONFIG_DIR/lua/plugins"
    cp "$DOTFILES/.config/nvim/init.lua" "$NVIM_CONFIG_DIR/init.lua"
    cp "$DOTFILES/.config/nvim/nvim-pack-lock.json" "$NVIM_CONFIG_DIR/nvim-pack-lock.json"
    cp "$DOTFILES/.config/nvim/lua/plugins/"*.lua "$NVIM_CONFIG_DIR/lua/plugins/"
  }

  if command -v stow >/dev/null 2>&1; then
    echo "    Using stow..."
    deploy_n_stow
  elif command -v ln >/dev/null 2>&1; then
    echo "    Creating symlinks..."
    deploy_n_ln
  else
    echo "    Copying files..."
    deploy_n_cp
  fi
  echo "  [nvim] Done."
}

# ==================================================
# Main
# ==================================================
main() {
  echo "==> Installing dotfiles..."

  task_bash_preexec
  task_tpm
  task_tmux_config
  task_fzf
  task_zoxide
  task_fd
  task_sesh
  task_tv
  task_atuin
  task_ghostty
  task_install_ghostty
  task_yazi
  task_maple_font
  task_nvim
  # task_git        # TODO

  echo ""
  echo "==> All done!"
  echo "    Run:  source ~/.bashrc"
  echo "    Then: tmux source-file ~/.config/tmux/tmux.conf"
  echo "    Then in tmux: Prefix + I  (install plugins)"
}

main "$@"
