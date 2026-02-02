<h1 align=center>TMUX INSTALLER</h1>
<h3 align=center>Download → Build → Install or Update</h3>
<br>

> [!IMPORTANT]
> - Tested and working on **debian 12**
> - Currently requires `dpkg` and `apt` for dependency management
> - Try installer in a VM _before_ your main system

An unofficial installer for the official [tmux](https://github.com/tmux/tmux) project. Use it to install **tmux** on a new system or upgrade an existing install. You may also use it to download and install fonts directly from the latest [NerdFonts](https://github.com/ryanoasis/nerd-fonts) release.

See [docs/todo.md](/docs/todo.md) for planned features.

### Rationale

If you setup Linux systems on a regular basis, you'll know having access to convenient tools which expidite the initial system configuration is a priority. I frequently find myself in a new VM for development/testing purposes and, as a programmer, I'm of course always looking for ways to automate the setup process. This installer was _long_ overdue, given I've had to install **tmux** more times than I can count.

## Usage

> [!NOTE]
> - For a root install of **TPM**, you must _login_ as `root` -- the installer relies on `$SUDO_USER` to handle execution with `sudo`.
> - See [options](#options) for commandline args.

```bash
git clone https://github.com/worldshredder/tmux-installer.git &&\
    sudo tmux-installer/src/install.sh
```

## Options

```
Usage: install.sh [OPTIONS...]

Options:
  -r, --release RELEASE  Specificy a Tmux release to download and install.
  -f, --fonts FONTS      A comma separated list of Nerd Fonts to install.
  -o, --otf              Install opentype fonts if available.
  -F, --fonts-only       Install fonts only.
  -d, --plugins-dir DIR  Specify the Tmux plugins directory path. The default
                         path is '~/.tmux/plugins'.
      --no-tpm           Do not install Tmux Plugin Manager (TPM).
      --no-tmux          Do not install Tmux.
  -u, --user USER        User to install Tmux plugins on. Overrides \$SUDO_USER
                         and \$USER. See notes for more info.
  -l, --ls               List available versions and release dates.
  -L, --ls-fonts         List available Nerd Fonts.
  -V, --verbose          Enable verbose apt/git/make/install
  -v, --version          Print installer version.
  -h, --help             Print this help message.

Environment:
  TMUX_RELEASE        Same as -r|--release
  INSTALL_FONTS       Same as -f|--fonts
  TMUX_PLUGINS_DIR    Same as -d|--plugins-dir
  INSTALL_TPM         Expects 'true' or 'false'; set by --no-tpm
  INSTALL_TMUX        Expects 'true' or 'false'; set by --no-tmux
  VERBOSE             Expects 'true' or 'false'; set by -V
```

> [!NOTE]
> When executing with sudo, the installer will assume a default plugins directory of `/home/$SUDO_USER/.tmux/plugins` unless specified otherwise with `--plugins-dir` or `--user`. If `$SUDO_USER` is empty, `$USER` is used.

## Examples

- #### Install latest Tmux release

    ```bash
    sudo src/install.sh
    ```

- #### Install Tmux release `3.6` with `JetbrainsMono` font

    ```bash
    sudo src/install.sh -r 3.6 -f jetbrainsmono
    ```

- #### Install fonts only (no Tmux)

    ```bash
    sudo src/install.sh -Ff arimo,noto,tinos
    ```

- #### List available Tmux releases

    ```bash
    src/install.sh -l
    ```

- #### List available [NerdFonts](https://github.com/ryanoasis/nerd-fonts)

    ```bash
    src/install.sh -L
    ```

