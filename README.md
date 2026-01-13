# Dotfile

## Setup

[GNU Stow](https://www.gnu.org/software/stow/) symlinks files to `~`, keeping dotfiles version-controlled in one place.

```bash
brew install stow
stow -t ~ .
```

Stow creates symlinks, not copies. Changes are instant. Re-run `stow` only when adding new files.