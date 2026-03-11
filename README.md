# dotfiles

## tmux

This repo includes a tmux config at `.config/tmux/.tmux.conf` and a reusable setup script.

### Setup

```sh
bash scripts/tmux-setup.sh
```

Dry-run:

```sh
bash scripts/tmux-setup.sh --dry-run
```

Options:

```sh
# Do not install TPM
bash scripts/tmux-setup.sh --skip-tpm

# Do not reload running tmux
bash scripts/tmux-setup.sh --skip-reload
```

After setup, inside tmux press `prefix + I` to install plugins via TPM.
