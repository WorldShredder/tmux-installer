<h1 align=center>TMUX INSTALLER</h1>
<h3 align=center>Planned Features & Dev Todo</h3>
<br>

## Planned Features

- [ ] **(option)** Tmux install path, e.g.: `-D /opt/tmux`
- [ ] **(feature)** Tmux config generator & installer
- [ ] **(feature)** Route to build Tmux from version control
- [ ] **(feature)** Tmux plugin browser
- [ ] **(feature)** Dependency management compatibility for _Fedora (dnf/yum)_ and _Arch (pacman)_
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

- [ ] Installer should quit if invalid release is given, rather than download latest version.
- [ ] `tmux_post_install` should update Whonix patch line in `.zshrc` if it exists.
- [ ] Tmux config installer needs to check for local and remote content.
- [ ] All common commands should be called with user `__USER__`:
    
    <details>
    <summary>Details</summary>
    
    This will ensure smooth operation when using commands like `cp` and `mv`.
    
    ```bash
    curl() { sudo -u "$__USER__" curl "$@" ; }
    git()  { sudo -u "$__USER__" git "$@" ; }
    # and so on...
    ```
    
    </details>

