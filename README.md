<h1 align=center>TMUX INSTALLER</h1>
<h3 align=center>Download → Build → Install or Update</h3>
<br>

An unofficial installer for the official [tmux](https://github.com/tmux/tmux) project. Use it to install **tmux** on a new system or upgrade an existing install.

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
  -v, --version       Print installer version.
  -h, --help          Print this help message.

Environment:
  TMUX_RELEASE        Same as -r|--release
  INSTALL_FONTS       Same as -f|--fonts
  INSTALL_TMUX        Expects 'true' or 'false'; set by -F
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
- [ ] Option to install a given `.tmux.conf`.
- [ ] Add route to build from version control.
- [ ] Implement proper logging.
