<h1 align=center>TMUX INSTALLER</h1>
<h3 align=center>Download → Build → Install or Update</h3>
<br>

> [!IMPORTANT]
> - Tested and working on **debian 12**
> - Requires `dpkg` and `apt` for dependency management (see [todo](#todo))
> - Try installer in a VM _before_ your main system.

An unofficial installer for the official [tmux](https://github.com/tmux/tmux) project. Use it to install **tmux** on a new system or upgrade an existing install. You may also use it to download and install fonts directly from the latest [NerdFonts](https://github.com/ryanoasis/nerd-fonts) release.

### Rationale

If you setup Linux systems on a regular basis, you'll know having access to convenient tools which expidite the initial system configuration is a priority. I frequently find myself in a new VM for development/testing purposes and, as a programmer, I'm of course always looking for ways to automate the setup process. This installer was _long_ overdue, given I've had to install **tmux** more times than I can count.

## Usage

> [!NOTE]
> See [options](#options) for commandline args.

- #### (A) Run Via Curl

    ```bash
    bash <(curl -sL https://github.com/WorldShredder/tmux-installer/raw/refs/heads/main/src/install.sh)
    ```
    
- #### (B) Clone Repo & Run

    ```bash
    git clone https://github.com/worldshredder/tmux-installer.git
    bash tmux-installer/src/install.sh
    ```

## Options

```
Usage: src/install.sh [OPTIONS...]

Options:
  -r, --release       Specificy a Tmux release to download and install.
  -f, --fonts         A comma separated list of Nerd Fonts to install.
  -o, --otf           Install opentype fonts if available.
  -F, --fonts-only    Install fonts only.
  -l, --ls            List available versions and release dates.
  -L, --ls-fonts      List available Nerd Fonts.
  -V, --verbose       Enable verbose apt and make/install
  -v, --version       Print installer version.
  -h, --help          Print this help message.

Environment:
  TMUX_RELEASE        Same as -r|--release
  INSTALL_FONTS       Same as -f|--fonts
  INSTALL_TMUX        Expects 'true' or 'false'; set by -F
  VERBOSE             Expects 'true' or 'false'; set by -V
```

## Examples

- #### Install latest Tmux release

    ```bash
    bash src/install.sh
    ```

- #### Install Tmux release `3.6` with `JetbrainsMono` font

    ```bash
    bash src/install.sh -r 3.6 -f jetbrainsmono
    ```

- #### Install fonts only (no Tmux)

    ```bash
    bash src/install.sh -Ff arimo,noto,tinos
    ```

- #### List available Tmux releases

    ```bash
    bash src/install.sh -l
    ```

- #### List available [NerdFonts](https://github.com/ryanoasis/nerd-fonts)

    ```bash
    bash src/install.sh -L
    ```

## Todo

- [ ] Option to remove current installation of **tmux**.
- [ ] Option to define installation directory.
- [x] Option to define a [NerdFont](https://www.nerdfonts.com/) for install.
- [ ] Option to install a given `.tmux.conf` from file and URL.
- [ ] Add route to build from version control.
- [ ] Implement proper logging.
- [ ] Option to install & configure TPM.
- [ ] Dependency management for `yum`, `dnf`, `pacman`.
