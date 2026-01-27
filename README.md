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

| Option | Description |
| ------ | ----------- |
| -l \| --ls | List all available versions and release dates.
| -r \| --release RELEASE | Specificy a **tmux** release to install.
| -v \| --version | Print installer version.
| -h \| --help | Print help message.

### Environment

You can also define the desired release by declaring `TMUX_RELEASE=<release>`, e.g., `TMUX_RELEASE='3.6' bash src/installer.sh`.

## Todo

- [ ] Option to remove current installation of **tmux**.
- [ ] Option to define installation directory.
- [ ] Option to define a [NerdFont](https://www.nerdfonts.com/) for install.
    ```bash
    list_nerd_fonts() {
        :
    }
    get_nerd_font() {
        local font_name="${1}.tar.xz"
        local api_url="https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
        jq -r ".assets | .[] | select(.name == \"$font_name\") |\
            .browser_download_url" <(curl -sL "$api_url")
    }
    get_nerd_font 'Monofur'
    ```
- [ ] Option to install a given `.tmux.conf`.
- [ ] Add route for compiling from source.
