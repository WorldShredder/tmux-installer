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
Usage: installer [OPTIONS...]

Options:
  -r, --release       Specificy a Tmux release to install.
  -f, --fonts         A comma separated list of Nerd Fonts to install.
  -o, --otf           Install opentype fonts if available.
  -F, --fonts-only    Install fonts only.
  -l, --ls            List available versions and release dates.
  -L, --ls-fonts      List available Nerd Fonts.
  -v, --version       Print installer version.
  -h, --help          Print this help message.
```

### Environment

| Variable | Description
| -------- | -----------
| TMUX\_RELEASE=<release> | Specify a **tmux** release to install; same as `-r`.
| INSTALL\_FONTS | A comma separated list of [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) to install; same as `-f`.

## Todo

- [ ] Option to remove current installation of **tmux**.
- [ ] Option to define installation directory.
- [ ] Option to define a [NerdFont](https://www.nerdfonts.com/) for install.
    ```bash
    NF_API_URL="https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
    list_nerd_fonts() {
        jq -r '.assets | .[] | .name | sub("(\\.zip|\\.tar\\.xz)$"; "")' \
            <(curl "NF_API_URL")
    }
    get_nerd_font() {
        local font_name="${1}.tar.xz"
        jq -r ".assets | .[] | select(.name == \"$font_name\") |\
            .browser_download_url" <(curl -sL "$NF_API_URL")
    }
    get_nerd_font 'Monofur'
    ```
- [ ] Option to install a given `.tmux.conf`.
- [ ] Add route for compiling from source.
