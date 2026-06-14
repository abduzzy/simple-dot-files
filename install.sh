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
    echo "$line" >> "$file"
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
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
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
    }

    deploy_with_cp() {
        mkdir -p "$TMUX_CONFIG_DIR"
        cp "$DOTFILES/.config/tmux/tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
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
            x86_64)  ARCH="x86_64" ;;
            aarch64) ARCH="aarch64" ;;
            *)       echo "    Unsupported architecture: $ARCH"; exit 1 ;;
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
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        *)       echo "    Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    SESH_URL="https://github.com/joshmedeski/sesh/releases/latest/download/sesh_linux_${ARCH}.tar.gz"
    curl -fsSL "$SESH_URL" | tar xz -C "$LOCAL_BIN" sesh
    chmod +x "$LOCAL_BIN/sesh"
    echo "    Installed to $LOCAL_BIN/sesh"
    echo "  [sesh] Done."
}

# ==================================================
# Task: Install tv (television) binary
# ==================================================
task_tv() {
    echo "  [tv] Installing..."

    ensure_local_bin
    if command -v tv >/dev/null 2>&1; then
        echo "    Binary already installed at $(command -v tv)"
        echo "  [tv] Done."
        return
    fi

    echo "    Downloading latest tv binary..."
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  ARCH="x86_64" ;;
        aarch64) ARCH="aarch64" ;;
        *)       echo "    Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    TV_URL="https://github.com/alexpasmantier/television/releases/latest/download/television-${ARCH}-unknown-linux-musl.tar.gz"
    curl -fsSL "$TV_URL" | tar xz -C "$LOCAL_BIN"
    chmod +x "$LOCAL_BIN/tv"
    echo "    Installed to $LOCAL_BIN/tv"
    echo "  [tv] Done."
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
            x86_64)  ARCH="x86_64" ;;
            aarch64) ARCH="aarch64" ;;
            *)       echo "    Unsupported architecture: $ARCH"; exit 1 ;;
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
    }

    deploy_g_cp() {
        mkdir -p "$GHOSTTY_CONFIG_DIR"
        cp "$DOTFILES/.config/ghostty/config" "$GHOSTTY_CONFIG_DIR/config"
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
    echo "  [ghostty-app] Installing/updating ghostty..."
    echo "    Running ghostty-ubuntu install script..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
    echo "  [ghostty-app] Done."
}

# ==================================================
# Main
# ==================================================
main() {
    echo "==> Installing dotfiles..."

    task_tpm
    task_tmux_config
    task_fzf
    task_zoxide
    task_sesh
    task_tv
    task_atuin
    task_ghostty
    task_install_ghostty
    # task_nvim       # TODO
    # task_git        # TODO

    echo ""
    echo "==> All done!"
    echo "    Run:  source ~/.bashrc"
    echo "    Then: tmux source-file ~/.config/tmux/tmux.conf"
    echo "    Then in tmux: Prefix + I  (install plugins)"
}

main "$@"
