<h1 align=center>TMUX INSTALLER</h1>
<h3 align=center>Planned Features & Dev Todo</h3>
<br>

## Planned Features

- [ ] **(option)** Tmux install path, e.g.: `-D /opt/tmux`
- [ ] **(feature)** Tmux config generator
- [x] **(feature)** Tmux config installer
- [ ] **(feature)** Route to build Tmux from version control
- [ ] **(feature)** Tmux plugin browser
- [ ] **(feature)** Fedora and Arch compatibility
- [x] **(feature)** [NerdFont](https://nerdfonts.com) installer
- [x] **(feature)** [Tmux Plugin Manager (TPM)](https://github.com/tmux-plugins/tpm) installer

## Developer Todo

- [ ] Create pre-git `shellcheck` + `shfmt` pipeline
- [ ] Implement better logging (maybe with `impish` module scheme)
- [x] Utilize `readonly` for constants
- [x] `mktemp_dir` should take a name reference to automate populating `__CLEANUP_TARGETS__`
    
    <details>
    <summary>Details</summary>
    
    At the moment `mktemp_dir` is called in a subshell during variable assignment which prevents appending the cleanup array. Solve by assignment of `build_dir` vars through nameref:
     
    ```bash
    mktemp_dir() {
        local -n n="$1"
        n="$(mktemp -d --suffix "$__TMP_SUFFIX__")"
        __CLEANUP_TARGETS__+=("$n")
    }
    ```
    
    ```bash
    local build_dir
    mktemp_dir build_dir
    ```
    
    </details>

- [x] Patch Whonix zsh prompt for tmux
    
    <details>
    <summary>Details</summary>
    
    Whonix does not check if `TERM=tmux-*` and thus does not correctly apply `PS1`. According to Tmux docs, it relies on the value of `TERM` to properly function, so best not to change its value permanently.
    
    Whonix determines `PS1` in `/etc/zsh/zshrc_prompt`. Add to `~/.zshrc`:
    
    ```bash
    [[ "$TERM" = tmux-* ]] &&\
        TERM='xterm-256color' source /etc/zsh/zshrc_prompt
    ```
    
    </details>

- [x] Installer should quit if invalid release is given, rather than download latest version.
- [x] `tmux_post_install` should update Whonix patch line in `.zshrc` if it exists.
- [x] Tmux config installer needs to check for local and remote content.
- [x] All common commands should be called with user `__USER__`:
    
    <details>
    <summary>Details</summary>
    
    This will ensure smooth operation when using commands like `cp` and `mv`.
    
    ```bash
    run_user_command() {
        local cmd_name="$1"
        local cmd_path
        cmd_path="$(sudo -u "$__USER__" bash -c "command -v '$cmd_name'")"
        [ -n "$cmd_path" ] &&\
            sudo -u "$__USER__" "$cmd_path" "$@"
    }
    ```
    
    </details>

- [ ] Consider handling error messages using named pipes.
    
    <details>
    <summary>Details</summary>
    
    Useful for communicating out of subshells, which are employed frequently in the tmux installer. FIFOs will also benefit a modular rewrite, although it may be more appropriate to maintain a unified script to allow install via stdin.
    
    Using FIFOs are better for logging in general as they easily permit the combination of foreground and background logging:
    
    ```bash
    export FOO_LOGGER="$(mktemp -u --suffix ".${BASHPID}.logger")"
    mkfifo "$FOO_LOGGER"
    
    # Alternatively direct to journal
    tail -f "$FOO_LOGGER" > log.txt &
    
    process_bar &>"$FOO_LOGGER"
    ```
    
    </details>

- [x] `nf_install_font()` only attempts to extract _otf_ if `PREFER_OTF` is _true_.
    
    <details>
    <summary>Details</summary>
    
    `nf_install_font()` attempts to extract _otf_ fonts if `PREFER_OTF=true` but not when _ttf_ extraction fails (no `.ttf` fonts).
    
    Extract operation should be a function instead:
    
    ```bash
    nf_unpack_font() {
        local src="$1"
        local dest="$2"

        local order='.ttf .otf'
        [ "$PREFER_OTF" == 'true' ] &&\
            order='.otf .ttf'

        for font_type in $order ; do
            user_tar -xJf "$src" -C "$dest" --wildcard "*$font_type" &>"$__STDERR__" ||\
                continue
            printf "$font_type"
            return
        done
        return 1
    }
    ```
    
    </details>

- [ ] `TMUX_CLIPBOARD_PKG` should be set based on display manager rather than defaulting to `xclip`.
- [ ] `-F` option should not require `-f` to install fonts only.
