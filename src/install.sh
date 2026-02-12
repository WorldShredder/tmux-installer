#!/usr/bin/env bash

# github.com/tmux/tmux
# github.com/worldshredder/tmux-installer

######################################################################
##                                                                  ##
## - Downloads and installs the latest version of Tmux and TPM      ##
##                                                                  ##
## - Install one or more NerdFonts from 'ryanoasis/nerd-fonts'      ##
##                                                                  ##
## - Handles necessary compiler dependencies (apt only atm)         ##
##                                                                  ##
## - See -h|--help for more options                                 ##
##                                                                  ##
######################################################################

set -Eeo pipefail

readonly __VERSION__='0.4.0'
readonly __TMP_SUFFIX__='.tmux-installer'
readonly __FD2__="/proc/${BASHPID}/fd/2"
__STDERR__='/dev/null'
# __STDOUT__='/dev/null'
__CLEANUP_TARGETS__=()

# We should assume installer will be ran with `sudo` which means we need to
# get the sudoer's $HOME instead of root's.

__USER__="${SUDO_USER:-$USER}"
__HOME__="$(sudo -u "$__USER__" bash -c 'echo $HOME')"

# For Whonix, we cannot rely on $WHONIX because it is not available in root.
# This means running installer with sudo will skip whonix-depends.

if command -v whonix &>/dev/null ; then
    readonly WHONIX=1
else
    readonly WHONIX=0
fi

readonly GITHUB_API_URL="https://api.github.com/repos"
readonly NF_API_URL="${GITHUB_API_URL}/ryanoasis/nerd-fonts/releases/latest"
readonly TMUX_API_URL="${GITHUB_API_URL}/tmux/tmux/releases"
readonly TPM_REPO_URL='https://github.com/tmux-plugins/tpm'

# Accepted environment variables
TMUX_PLUGINS_DIR="${TMUX_PLUGINS_DIR:-${__HOME__}/.tmux/plugins}"
TMUX_CLIPBOARD_PKG="${TMUX_CLIPBOARD_PKG:-xclip}"
INSTALL_TMUX="${INSTALL_TMUX:-true}"
INSTALL_TPM="${INSTALL_TPM:-true}"
PREFER_OTF="${PREFER_OTF:-false}"
VERBOSE="${VERBOSE:-false}"

# Triggered if not installing tmux or tpm
NO_INSTALL='false'

NF_BUILD_DIR=''
TMUX_BUILD_DIR=''

cleanup() {
    trap - ERR INT TERM HUP QUIT
    trap 'exit 1' ERR
    trap 'exit 0' INT TERM HUP QUIT
    local target
    for target in "${__CLEANUP_TARGETS__[@]}" ; do
        [ -d "$target" ] || [ -f "$target" ] &&\
            rm -rf "$target"
    done
}

mktemp_dir() {
    local -n nameref="$1"
    local suffix="${2:-$__TMP_SUFFIX__}"
    nameref="$(sudo -u "$__USER__" mktemp -d --suffix "$suffix")"
    __CLEANUP_TARGETS__+=("$nameref")
}

# TODO: Implement FIFO logging
# mktemp_fifo() {
#     local -n nameref="$1"
#     local suffix="${2:-$__TMP_SUFFIX__}"
#     nameref="$(sudo -u "$__USER__" mktemp -u --suffix "$suffix")"
#     sudo -u "$__USER__" mkfifo "$nameref"
#     __CLEANUP_TARGETS__+=("$nameref")
# }

print_help() {
cat << EOF
Usage: $0 [OPTIONS...]

Install the latest version of Tmux and specified NerdFonts.

Options:
  -r, --release RELEASE  Specificy a Tmux release to download and install.
  -f, --fonts FONTS      A comma separated list of Nerd Fonts to install.
  -o, --otf              Install opentype fonts if available.
  -F, --fonts-only       Install fonts only.
  -c, --config PATH      Path to a tmux config. If PATH is a URL, the installer
                         will curl it and expect a raw output.
  -d, --plugins-dir DIR  Specify the Tmux plugins directory path. The default
                         path is '~/.tmux/plugins'.
      --no-tpm           Do not install Tmux Plugin Manager (TPM).
      --no-tmux          Do not install Tmux.
      --clipboard PKG    Specify a clipboard package to install for Tmux.
                         Default is 'xclip'.
  -u, --user USER        User to install Tmux plugins and config on. Overrides
                         \$SUDO_USER and \$USER. See notes for more info.
  -l, --ls               List available versions and release dates.
  -L, --ls-fonts         List available Nerd Fonts.
  -V, --verbose          Enable verbose apt/git/make/install
  -v, --version          Print installer version.
  -h, --help             Print this help message.

Environment:
  TMUX_RELEASE        Same as -r|--release
  INSTALL_FONTS       Same as -f|--fonts
  TMUX_CONFIG_PATH    Same as -c|--config
  TMUX_PLUGINS_DIR    Same as -d|--plugins-dir
  TMUX_CLIPBOARD_PKG  Same as --clipboard
  INSTALL_TPM         Expects 'true' or 'false'; set by --no-tpm
  INSTALL_TMUX        Expects 'true' or 'false'; set by --no-tmux
  PREFER_OTF          Expects 'true' or 'false'; set by --otf
  VERBOSE             Expects 'true' or 'false'; set by -V

Examples:
  # Install latest verion
      $0
  # Install version '3.6'
      $0 -r 3.6
  # Install latest version with three fonts
      $0 -f jetbrainsmono,meslo,hermit
  # Install font 'monofur' only
      $0 -Ff monofur

Notes:
  When executing with sudo, the installer will assume a default plugins
  directory of '/home/\$SUDO_USER/.tmux/plugins' unless specified otherwise
  with --plugins-dir or --user. If \$SUDO_USER is empty, \$USER is used

https://github.com/WorldShredder
tmux-installer v${__VERSION__}
EOF
}

parse_opts() {
    set -Cu
    local short_opts long_opts params
    short_opts='r:f:oFc:d:u:lLVvh'
    long_opts='tmux-release:,fonts:,config:,otf,fonts-only,plugins-dir:,no-tmux,no-tpm,clipboard:,user:,ls,ls-fonts,verbose,version,help'
    params="$(
        getopt -o "$short_opts" -l "$long_opts" --name "$0" -- "$@"
    )"
    eval set -- "$params" && set +Cu
    
    while true ; do
        case "$1" in
            -r|--release)
                TMUX_RELEASE="$2"
                shift 2 ;;
            -f|--fonts)
                INSTALL_FONTS="$2"
                shift 2 ;;
            -o|--otf)
                PREFER_OTF='true'
                shift ;;
            -F|--fonts-only)
                INSTALL_TMUX='false'
                INSTALL_TPM='false'
                shift ;;
            -c|--config)
                TMUX_CONFIG_PATH="$2"
                shift 2 ;;
            -d|--plugins-dir)
                TMUX_PLUGINS_DIR="$2"
                shift 2 ;;
            --no-tmux)
                INSTALL_TMUX='false'
                shift ;;
            --no-tpm)
                INSTALL_TPM='false'
                shift ;;
            --clipboard)
                TMUX_CLIPBOARD_PKG="$2"
                shift 2 ;;
            -u|--user)
                __USER__="$2"
                __HOME__="$(sudo -u "$__USER__" bash -c 'echo $HOME')"
                TMUX_PLUGINS_DIR="${__HOME__}/.tmux/plugins"
                shift 2 ;;
            -l|--ls)
                NO_INSTALL='true'
                check_depends
                tmux_list_releases
                exit 0 ;;
            -L|--ls-fonts)
                NO_INSTALL='true'
                check_depends
                nf_list_fonts
                exit 0 ;;
            -V|--verbose)
                VERBOSE='true'
                shift ;;
            -v|--version)
                echo "Tmux Installer $__VERSION__"
                exit 0 ;;
            -h|--help)
                print_help
                exit 0 ;;
            --)
                shift
                break ;;
            *)
                echo -e "\e[31m[ERROR] Invalid option '$1'\e[0m"
                return 1 ;;
        esac
    done
}

install_depends() {
    local missing_pkgs="$1"

    echo -ne '\e[34m[INFO ] Updating apt package lists ... \e[0m'
    sudo apt update &>"$__STDERR__" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'

    echo -ne '\e[34m[INFO ] Installing missing packages ... \e[0m'
    sudo apt install -y $missing_pkgs \
    --no-install-recommends &>"$__STDERR__" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'
}

check_depends() {
    # jq and curl required for --ls and --ls-fonts
    declare -a REQUIRED_PKGS=('jq' 'curl')

    [ "$INSTALL_TMUX" == 'true' ] &&\
    [ "$NO_INSTALL" == 'false' ] &&\
    {
        REQUIRED_PKGS+=('mktemp' 'xargs' 'bison' 'libevent-dev'
                        'libncurses-dev' 'make' 'gcc')
        REQUIRED_PKGS+=("$TMUX_CLIPBOARD_PKG")
    }

    [ "$INSTALL_TPM" == 'true' ] &&\
    [ "$NO_INSTALL" == 'false' ] &&\
    {
        REQUIRED_PKGS+=('git')
    }

    declare -a missing_pkgs
    for pkg in "${REQUIRED_PKGS[@]}" ; do
        ! dpkg -s "$pkg" &>/dev/null && ! type "$pkg" &>/dev/null &&\
            missing_pkgs+=("$pkg")
    done

    # Whonix compatibility
    [ "$WHONIX" == '1' ] &&\
    [ "$NO_INSTALL" == 'false' ] &&\
    [ "$INSTALL_TPM" == 'true' ] &&\
    [ ! -f '/usr/bin/git.anondist-orig' ] &&\
    {
        missing_pkgs+=('git')
    }

    [ "${#missing_pkgs[@]}" -lt 1 ] &&\
        return

    echo -e "\e[33m[WARN ] Missing required packages: ${missing_pkgs[*]}\e[0m"
    while [ "${#missing_pkgs[@]}" -gt 0 ] ; do
        echo -ne "\e[34m[--?--]-> Install missing packages (y/n) \e[0m"
        read -p ''
        case "$REPLY" in
            [yY])
                install_depends "${missing_pkgs[*]}"
                break ;;
            [nN])
                return 1 ;;
            *)
                echo -e "\e[33m[WARN ] Invalid response '$REPLY'\e[0m" ;;
        esac
    done
}

nf_get_fonts() {
    local query='.assets | .[] | {name: .name, location: .browser_download_url}'
    jq "$query" <(curl -fsL "$NF_API_URL") 2>/dev/null
}

nf_list_fonts() {
    local font_data
    font_data="$(nf_get_fonts)"
    local query='.name | select(. | test("\\.tar\\.xz$")) | sub("\\.tar\\.xz$";"")'
    jq -r "$query" <<< "$font_data"
}

nf_get_location() {
    local font font_data
    font_name="${1,,}"
    font_data="${2:-$(nf_get_fonts)}"

    local query="select(.name | ascii_downcase | \
        test(\"^${font_name}\\\.tar\\\.xz\$\")) | .location"

    jq -r "$query" <<< "$font_data" 2>/dev/null |\
        grep -oE '^https://github\.com/ryanoasis/nerd-fonts/.+'
}

nf_extract_font() {
    local src="$1"
    local dest="$2"
    local order="${3:-ttf otf}"

    for ftype in $order ; do
        user_tar -xJf "$src" -C "$dest" --wildcards "*.$ftype" &>"$__STDERR__" ||\
            continue
        printf "$ftype"
        return
    done
    return 1
}

nf_install_font() {
    local font_name="$1"
    local font_data="$2"
    if [ -z "$font_data" ] ; then
        echo -ne "\e[34m[INFO ] Fetching NerdFonts metadata ... \e[0m"
        font_data="$(nf_get_fonts)" ||\
        {
            echo -e '\e[31mFAIL\e[0m'
            return 1
        }
        echo -e '\e[32mOK\e[0m'
    fi

    local location
    location="$(nf_get_location "$font_name" "$font_data")"

    local build_dir
    mktemp_dir build_dir

    local system_fonts='/usr/share/fonts'
    local font_archive="${build_dir}/${font_name}.tar.xz"
    local data_dir="${build_dir}/font_data"
    user_mkdir "$data_dir"

    local preference='ttf otf'
    [ "$PREFER_OTF" == 'true' ] &&\
        preference='otf ttf'

    echo -ne "\e[34m[INFO ] Downloading font \e[35m${font_name} \e[34m ... \e[0m"
    user_curl -fsSL "$location" -o "$font_archive" &>"$__STDERR__" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'

    echo -ne "\e[34m[INFO ] Extracting font \e[35m${font_name} \e[34m... \e[0m"
    local font_type
    font_type="$(nf_extract_font "$font_archive" "$data_dir" "$preference")" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'

    echo -ne "\e[34m[INFO ] Installing font \e[35m${font_name}"\
        "(${font_type^^}) \e[34m... \e[0m"
    local install_path="${system_fonts}/truetype/${font_name}"
    [ "$font_type" == 'otf' ] &&\
        install_path="${system_fonts}/opentype/${font_name}"
    sudo mkdir -p "$install_path" 2>"$__STDERR__" &&\
    sudo cp "$data_dir"/*."$font_type" "$install_path" 2>"$__STDERR__" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'
}

nf_install_fonts() {
    local font_data="$1"
    if [ -z "$font_data" ] ; then
        echo -ne "\e[34m[INFO ] Fetching NerdFonts metadata ... \e[0m"
        font_data="$(nf_get_fonts)" ||\
        {
            echo -e '\e[31mFAIL\e[0m'
            return 1
        }
        echo -e '\e[32mOK\e[0m'
    fi
    local font_name
    while read -rd ',' font_name ; do
        nf_install_font "$font_name" "$font_data"
    done <<< "${INSTALL_FONTS},"
}

tmux_get_release() {
    local release="$1"
    if [ -z "$release" ] || [ "$release" == 'all' ] ; then
        curl -fsL "$TMUX_API_URL"
    elif [ "$release" == 'latest' ] ; then
        curl -fsL "${TMUX_API_URL}/latest"
    else
        local query=".[] | select(.tag_name == \"${release}\")"
        curl -fsL "${TMUX_API_URL}" | jq "$query" 2>/dev/null
    fi
}

tmux_list_releases() {
    local release_data
    release_data="${1:-$(tmux_get_release)}"

    local ln_format='echo -ne "\e[35m${0}\t\e[36m$(date -d "$1" "+%F")\e[0m\n"'
    local query='[.[] | "\(.tag_name)\t\(.assets[0].updated_at)"] | reverse | .[]'
    jq -r "$query" <<< "$release_data" 2>/dev/null |\
        xargs -n2 bash -c "$ln_format" 2>/dev/null
}

tmux_get_location() {
    local release="$1"
    local release_data="${2:-$(tmux_get_release "${1:-latest}")}"
    local query='. | .assets[0].browser_download_url'
    jq -r "$query" <<< "$release_data" 2>/dev/null |\
        grep -oE '^https://github\.com/.+'
}

tmux_get_tag_name() {
    # TODO consider .name (tmux x.y) for direct comparison with `tmux -V`
    local release_data="$1"
    local query='.tag_name'
    jq -r "$query" <<< "$release_data" 2>/dev/null
}

tmux_verify_install() {
    local release_data="$1"
    local tag_name="$2"

    echo -e "\e[34m[INFO ] Verifying Tmux install\e[0m"
    echo -ne '  \e[34m- Command `tmux` available ... '
    ! type tmux &>/dev/null &&\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'

    local current_version
    current_version="$(tmux -V | awk '{print $2}')"
    echo -ne "  \e[34m- Tmux version check ... "
    if [ "$tag_name" != "$current_version" ] ; then
        echo -e "\e[33mWARN ('$tag_name' != '$current_version')\e[0m"
    else
        echo -e '\e[32mOK\e[0m'
    fi
}

tmux_install() {
    # Only use 'all' where large datasets are needed, e.g.: --ls
    [ -z "$TMUX_RELEASE" ] || [ "${TMUX_RELEASE,,}" == 'all' ] &&\
        TMUX_RELEASE='latest'

    # Should handle 'process ... OK|FAIL' dynamically with tput
    # This method will cause minor issues in vebose mode

    local release_data="$1"
    if [ -z "$release_data" ] ; then
        echo -ne "\e[34m[INFO ] Fetching Tmux \e[35m${TMUX_RELEASE} \e[34mmetadata ... "
        release_data="$(tmux_get_release "$TMUX_RELEASE")" && [ -n "$release_data" ] ||\
        {
            echo -e '\e[31mFAIL\e[0m'
            return 1
        }
        echo -e '\e[32mOK\e[0m'
    fi
    tag_name="$(tmux_get_tag_name "$release_data")"

    local location
    location="$(tmux_get_location '' "$release_data")"

    local build_dir
    mktemp_dir build_dir

    echo -ne "\e[34m[INFO ] Downloading Tmux \e[35m${tag_name} \e[34m... \e[0m"
    user_curl -fsSL "$location" | user_tar -xz -C "$build_dir" &>"$__STDERR__" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'
    cd "$build_dir"/tmux-*

    echo -ne "\e[34m[INFO ] Building Tmux from source ... \e[0m"
    sudo -u "$__USER__" ./configure &>"$__STDERR__" &&\
    user_make &>"$__STDERR__" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'

    echo -ne "\e[34m[INFO ] Installing Tmux ... \e[0m"
    sudo make install &>"$__STDERR__" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'

    tmux_verify_install "$release_data" "$tag_name"
}

tmux_install_config() {
    local config_path="$1"
    local build_dir
    mktemp_dir build_dir
    if [[ "$config_path" =~ ^https?://.*\.git ]] ; then
        echo -ne '\e[34m[INFO ] Cloning Tmux config ... \e[0m'
        user_clone "$config_path" "$build_dir" &>"$__STDERR__" ||\
        {
            echo -e '\e[31mFAIL\e[0m'
            return 1
        }
        echo -e '\e[32mOK\e[0m'
        config_path="${build_dir}/.tmux.conf"
    elif [[ "$config_path" =~ ^https?:// ]] ; then
        echo -ne '\e[34m[INFO ] Downloading Tmux config ... \e[0m'
        user_curl -fsSL "$config_path" -o "$build_dir"/.tmux.conf &>"$__STDERR__" ||\
        {
            echo -e '\e[31mFAIL\e[0m'
            return 1
        }
        echo -e '\e[32mOK\e[0m'
        config_path="${build_dir}/.tmux.conf"
    fi
    echo -ne '\e[34m[INFO ] Installing Tmux config ... \e[0m'
    user_cp -b "$config_path" "$__HOME__"/.tmux.conf &>"$__STDERR__" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'
}

tmux_post_install() {
    # See docs/todo.md: 'Patch Whonix zsh prompt for tmux'
    if [ "$WHONIX" == '1' ] && [ -f /etc/zsh/zshrc_prompt ] ; then
        echo -ne '\e[34m[INFO ] Patching Whonix prompt ... \e[0m'
        local patch_line='# tmux-installer_whonix-patch\n'
        patch_line+='[[ "$TERM" = tmux-* ]] &&\\\n'
        patch_line+='    TERM="xterm-256color" source /etc/zsh/zshrc_prompt'
        
        if grep -F "$(echo -e "$patch_line")" "$__HOME__"/.zshrc &>/dev/null ; then
            echo -e '\e[32mSKIP\e[0m'
        else
            echo -e "$patch_line" | user_tee -a "$__HOME__"/.zshrc &>/dev/null ||\
            {
                echo -e '\e[31mFAIL\e[0m'
                return 1
            }
            echo -e '\e[32mOK\e[0m'
        fi
    fi

    [ -n "$TMUX_CONFIG_PATH" ] &&\
        tmux_install_config "$TMUX_CONFIG_PATH"

    return 0
}

tpm_install() {
    if [ -d "${TMUX_PLUGINS_DIR}/tpm" ] ; then
        echo -ne '\e[34m[INFO ] Updating TPM ... \e[0m'
        rm -r "${TMUX_PLUGINS_DIR}/tpm" &>"$__STDERR__"
    else
        echo -ne '\e[34m[INFO ] Installing TPM ... \e[0m'
    fi
    user_clone "$TPM_REPO_URL" "${TMUX_PLUGINS_DIR}/tpm" &>"$__STDERR__" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'
    __CLEANUP_TARGETS__+=("${TMUX_PLUGINS_DIR}/tpm/.git")
}

installer() {
    [ -n "$INSTALL_FONTS" ] &&\
        nf_install_fonts

    if [ "$INSTALL_TMUX" == 'true' ] ; then
        tmux_install
        tmux_post_install
    fi

    [ "$INSTALL_TPM" == 'true' ] &&\
        tpm_install

    return 0
}

pre_install() {
    parse_opts "$@"
    [ "$VERBOSE" == 'true' ] &&\
        __STDERR__="$__FD2__"
    check_depends

    run_user_command() {
        local command_name="$1" ; shift
        local command_path
        command_path="$(sudo -u "$__USER__" bash -c "command -v '$command_name'" )"
        [ -n "$command_path" ] &&\
            sudo -u "$__USER__" "$command_path" "$@"
    }
    user_mkdir() {
        run_user_command 'mkdir' "$@"
    }
    user_cp() {
        run_user_command 'cp' "$@"
    }
    user_tee() {
        run_user_command 'tee' "$@"
    }
    user_curl() {
        run_user_command 'curl' "$@"
    }
    user_tar() {
        run_user_command 'tar' "$@"
    }
    user_git() {
        run_user_command 'git' "$@"
    }
    user_clone() {
        user_git clone --depth 1 "$@"
    }
    user_make() {
        run_user_command 'make' "$@"
    }
}

main() {
    pre_install "$@"
    if [ "$NO_INSTALL" != 'true' ] ; then
        installer
        echo -e '\e[32m[OK   ] All processes complete\e[0m'
    fi
    kill -TERM "$BASHPID"
}

print_trap_err() {
    local e='[FATAL] Oops, something went wrong!'
    [ "$VERBOSE" != 'true' ] &&\
        e+=' Try with --verbose'
    echo -e "\e[31m${e}\e[0m"
}

trap 'print_trap_err ; cleanup ; exit 1' ERR
trap 'cleanup ; exit 0' INT TERM HUP QUIT

main "$@"

