#!/usr/bin/env sh
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
TMUX_CONFIG_DIR="$HOME/.config/tmux"
TPM_DIR="$TMUX_CONFIG_DIR/plugins/tpm"

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
# Main — add new tasks here
# ==================================================
main() {
    echo "==> Installing dotfiles..."

    task_tpm
    task_tmux_config
    # task_nvim       # TODO
    # task_git        # TODO
    # task_zsh        # TODO
    # task_ghostty    # TODO

    echo ""
    echo "==> All done!"
    echo "    Reload tmux: tmux source-file ~/.config/tmux/tmux.conf"
    echo "    Then press Prefix + I to install plugins."
}

main "$@"
