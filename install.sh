#!/usr/bin/env sh
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
BASHRC="$HOME/.bashrc"
MISE_CONFIG_DIR="$HOME/.config/mise"
MISE_CONFIG_FILE="$MISE_CONFIG_DIR/config.toml"

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
# Utility: add mise activation before shell integrations
# ==================================================
ensure_mise_activation() {
  file="$1"
  line="$2"
  touch "$file"

  tmp="$file.tmp.$$"
  awk -v line="$line" '
    $0 == line { next }
    !done && ($0 ~ /eval "\$\(fzf --bash\)"/ ||
              $0 ~ /eval "\$\(zoxide init bash/ ||
              $0 ~ /eval "\$\(tv init bash\)"/ ||
              $0 ~ /eval "\$\(atuin init bash\)"/) {
      print line
      done = 1
    }
    { print }
    END { if (!done) print line }
  ' "$file" >"$tmp"
  mv "$tmp" "$file"
}

# ==================================================
# Task: Install mise + shell activation
# ==================================================
task_mise() {
  echo "  [mise] Installing..."

  ensure_local_bin
  if ! command -v mise >/dev/null 2>&1; then
    echo "    Running official mise installer..."
    curl -fsSL https://mise.run | sh
  else
    echo "    Binary already installed at $(command -v mise)"
  fi

  export PATH="$LOCAL_BIN:$PATH"

  echo "    Adding activation to ~/.bashrc..."
  ensure_mise_activation "$BASHRC" 'eval "$(mise activate bash)"'

  echo "  [mise] Done."
}

# ==================================================
# Task: Deploy mise config
# ==================================================
task_mise_config() {
  echo "  [mise] Deploying mise config..."

  mkdir -p "$MISE_CONFIG_DIR"

  backup_existing_mise_config() {
    if [ ! -e "$MISE_CONFIG_FILE" ] && [ ! -L "$MISE_CONFIG_FILE" ]; then
      return 0
    fi

    if [ -L "$MISE_CONFIG_FILE" ]; then
      current_target=$(readlink -f "$MISE_CONFIG_FILE" 2>/dev/null || true)
      repo_target=$(readlink -f "$DOTFILES/.config/mise/config.toml" 2>/dev/null || true)
      if [ "$current_target" = "$repo_target" ]; then
        return 0
      fi
    fi

    BACKUP_FILE="$MISE_CONFIG_FILE.bak.$(date +%Y%m%d%H%M%S)"
    echo "    Backing up existing config to $BACKUP_FILE"
    mv "$MISE_CONFIG_FILE" "$BACKUP_FILE"
  }

  deploy_m_stow() {
    backup_existing_mise_config
    cd "$DOTFILES"
    stow -R --target="$HOME" .
  }

  deploy_m_ln() {
    backup_existing_mise_config
    ln -sf "$DOTFILES/.config/mise/config.toml" "$MISE_CONFIG_FILE"
  }

  deploy_m_cp() {
    backup_existing_mise_config
    cp "$DOTFILES/.config/mise/config.toml" "$MISE_CONFIG_FILE"
  }

  if command -v stow >/dev/null 2>&1; then
    echo "    Using stow..."
    deploy_m_stow
  elif command -v ln >/dev/null 2>&1; then
    echo "    Creating symlinks..."
    deploy_m_ln
  else
    echo "    Copying files..."
    deploy_m_cp
  fi
  echo "  [mise] Done."
}

# ==================================================
# Task: Install mise-managed tools + shell integration
# ==================================================
task_mise_install() {
  echo "  [mise] Installing tools..."

  mise install

  echo "    Adding shell integration to ~/.bashrc..."
  ensure_line "$BASHRC" 'eval "$(fzf --bash)"'
  ensure_line "$BASHRC" 'eval "$(zoxide init bash --cmd cd)"'
  ensure_line "$BASHRC" 'eval "$(tv init bash)"'

  echo "  [mise] Done."
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
# Task: Deploy kitty config
# ==================================================
task_kitty() {
  echo "  [kitty] Deploying kitty config..."

  KITTY_CONFIG_DIR="$HOME/.config/kitty"

  deploy_k_stow() {
    cd "$DOTFILES"
    stow -R --target="$HOME" .
  }

  deploy_k_ln() {
    mkdir -p "$KITTY_CONFIG_DIR"
    ln -sf "$DOTFILES/.config/kitty/kitty.conf" "$KITTY_CONFIG_DIR/kitty.conf"
    ln -sf "$DOTFILES/.config/kitty/mocha.conf" "$KITTY_CONFIG_DIR/mocha.conf"
  }

  deploy_k_cp() {
    mkdir -p "$KITTY_CONFIG_DIR"
    cp "$DOTFILES/.config/kitty/kitty.conf" "$KITTY_CONFIG_DIR/kitty.conf"
    cp "$DOTFILES/.config/kitty/mocha.conf" "$KITTY_CONFIG_DIR/mocha.conf"
  }

  if command -v stow >/dev/null 2>&1; then
    echo "    Using stow..."
    deploy_k_stow
  elif command -v ln >/dev/null 2>&1; then
    echo "    Creating symlinks..."
    deploy_k_ln
  else
    echo "    Copying files..."
    deploy_k_cp
  fi
  echo "  [kitty] Done."
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
# Task: Deploy herdr config
# ==================================================
task_herdr_config() {
  echo "  [herdr] Deploying herdr config..."

  HERDR_CONFIG_DIR="$HOME/.config/herdr"

  deploy_h_stow() {
    cd "$DOTFILES"
    stow -R --target="$HOME" .
  }

  deploy_h_ln() {
    mkdir -p "$HERDR_CONFIG_DIR"
    ln -sf "$DOTFILES/.config/herdr/config.toml" "$HERDR_CONFIG_DIR/config.toml"
  }

  deploy_h_cp() {
    mkdir -p "$HERDR_CONFIG_DIR"
    cp "$DOTFILES/.config/herdr/config.toml" "$HERDR_CONFIG_DIR/config.toml"
  }

  if command -v stow >/dev/null 2>&1; then
    echo "    Using stow..."
    deploy_h_stow
  elif command -v ln >/dev/null 2>&1; then
    echo "    Creating symlinks..."
    deploy_h_ln
  else
    echo "    Copying files..."
    deploy_h_cp
  fi
  echo "  [herdr] Done."
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

  task_mise
  task_mise_config
  task_mise_install
  task_bash_preexec
  task_herdr_config
  task_atuin
  task_ghostty
  # task_install_ghostty
  task_kitty
  task_maple_font
  task_nvim
  # task_git        # TODO

  echo ""
  echo "==> All done!"
  echo "    Run:  source ~/.bashrc"
  echo "    Update mise tools: mise upgrade"
}

main "$@"
