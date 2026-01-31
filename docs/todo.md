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
- [ ] Utilize `readonly` for constants
- [ ] `mktemp_dir` should take a name reference to automate populating `__CLEANUP_TARGETS__`

    > At the moment `mktemp_dir` is called in a subshell during variable assignment which prevents appending the cleanup array. Solve by assignment of `build_dir` vars through nameref:
    > 
    > ```bash
    > mktemp_dir() {
    >     local -n n="$1"
    >     n="$(mktemp -d --suffix "$__TMP_SUFFIX__")"
    >     __CLEANUP_TARGETS__+=("$n")
    > }
    > ```
    > 
    > ```bash
    > local build_dir
    > mktemp_dir build_dir
    > ```

