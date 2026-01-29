#!/usr/bin/env bash

# github.com/tmux/tmux
# github.com/worldshredder/tmux-installer

######################################################################
##                                                                  ##
## - Downloads and installs the latest version of Tmux              ##
##                                                                  ##
## - Install one or more NerdFonts from 'ryanoasis/nerd-fonts'      ##
##                                                                  ##
## - Handles necessary compiler dependencies                        ##
##                                                                  ##
## - See -h|--help for more options                                 ##
##                                                                  ##
######################################################################

set -Eeo pipefail

__VERSION__='0.2.3'
__FD2__="/proc/${BASHPID}/fd/2"
__STDERR__='/dev/null'
__CLEANUP_TARGETS__=()

GITHUB_API_URL="https://api.github.com/repos"
NF_API_URL="${GITHUB_API_URL}/ryanoasis/nerd-fonts/releases/latest"
TMUX_API_URL="${GITHUB_API_URL}/tmux/tmux/releases"
PREFER_OTF='false'
INSTALL_TMUX="${INSTALL_TMUX:-true}"
NF_BUILD_DIR=''
TMUX_BUILD_DIR=''

cleanup() {
    trap - ERR INT TERM HUP QUIT
    trap 'exit 1' ERR
    trap 'exit 0' INT TERM HUP QUIT
    local target
    for target in "${__CLEANUP_TARGETS__[@]}" ; do
        if [ -d "$target" ] ; then
            rm -rf "$target"
        fi
    done
}

print_help() {
cat << EOF
Usage: $0 [OPTIONS...]

Install the latest version of Tmux and specified NerdFonts.

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

Examples:
  # Install latest verion
      $0
  # Install version '3.6'
      $0 -r 3.6
  # Install latest version with three fonts
      $0 -f jetbrainsmono,meslo,hermit
  # Install font 'monofur' only
      $0 -Ff monofur

https://github.com/WorldShredder
EOF
}

parse_opts() {
    set -Cu
    local short_opts long_opts params
    short_opts='r:f:oFlLVvh'
    long_opts='tmux-release:,fonts:,otf,fonts-only,ls,ls-fonts,verbose,version,help'
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
                shift ;;
            -l|--ls)
                if ! type curl &>/dev/null ; then
                    echo -e "\e[31m[ERROR] Missing required package 'curl'\e[0m"
                    return 1
                fi
                tmux_list_releases
                exit 0 ;;
            -L|--ls-fonts)
                if ! type curl &>/dev/null ; then
                    echo -e "\e[31m[ERROR] Missing required package 'curl'\e[0m"
                    return 1
                fi
                nf_list_fonts
                exit 0 ;;
            -V|--verbose)
                __STDERR__="$__FD2__"
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
    echo -ne '\e[34m[INFO ] Updating apt package lists ... \e[0m'
    sudo apt update &>"$__STDERR__" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'

    echo -ne '\e[34m[INFO ] Installing missing packages ... \e[0m'
    sudo apt install -y ${missing_pkgs[*]} \
    --no-install-recommends &>"$__STDERR__" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'
}

check_depends() {
    declare -a REQUIRED_PKGS=('jq' 'curl' 'mktemp' 'xargs' 'bison'
                              'libevent-dev' 'libncurses-dev' 'make' 'gcc')
    declare -a missing_pkgs
    for pkg in "${REQUIRED_PKGS[@]}" ; do
        ! dpkg -s "$pkg" &>/dev/null && ! type "$pkg" &>/dev/null &&\
            missing_pkgs+=("$pkg")
    done
    if [ "${#missing_pkgs[@]}" -gt 0 ] ; then
        echo -e "\e[33m[WARN ] Missing required packages: ${missing_pkgs[*]}\e[0m"
        while true ; do
            echo -ne "\e[34m[--?--]-> Install missing packages "\
                    "(\e[32mY\e[34m/\e[31mn\e[34m)\e[0m "
            read -n 1 -p ''
            case "$REPLY" in
                [yY]|'')
                    install_depends "${missing_packages[*]}"
                    break ;;
                [nN])
                    echo ; return 1 ;;
                *)
                    echo -e "\n\e[33m[WARN ] Invalid response '$REPLY'\e[0m" ;;
            esac
        done
    fi
}

nf_get_fonts() {
    local query='.assets | .[] | {name: .name, location: .browser_download_url}'
    jq "$query" <(curl -sL "$NF_API_URL") 2>/dev/null
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
    build_dir="$(mktemp -d 2>/dev/null)"
    __CLEANUP_TARGETS__+=("$build_dir")

    local font_archive data_dir
    font_archive="${build_dir}/${font_name}.tar.xz"
    data_dir="${build_dir}/font_data"
    mkdir "$data_dir"

    echo -ne "\e[34m[INFO ] Downloading font \e[35m${font_name} \e[34m ... \e[0m"
    curl -sL "$location" > "$font_archive" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'

    echo -ne "\e[34m[INFO ] Installing font \e[35m${font_name} \e[34m... \e[0m"
    if [ "$PREFER_OTF" == 'true' ] \
    && tar -xJf "$font_archive" -C "$data_dir" --wildcards '*.otf' 2>/dev/null ; then
        sudo mkdir -p "/usr/share/fonts/opentype/$font_name" &&\
        sudo cp "$data_dir"/*.otf "/usr/share/fonts/opentype/$font_name/" ||\
        {
            echo -e '\e[31mFAIL\e[0m'
            return 1
        }
    elif tar -xJf "$font_archive" -C "$data_dir" --wildcards '*.ttf' 2>/dev/null ; then
        sudo mkdir -p "/usr/share/fonts/truetype/$font_name" &&\
        sudo cp "$data_dir"/*.ttf "/usr/share/fonts/truetype/$font_name/" ||\
        {
            echo -e '\e[31mFAIL\e[0m' 
            return 1
        }
    fi
    echo -e '\e[32mOK\e[0m'
}

nf_install_fonts() {
    local fonts="$1"
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
    local font_name
    while read -rd ',' font_name ; do
        nf_install_font "$font_name" "$font_data"
    done <<< "${fonts},"
}

tmux_get_release() {
    local release="$1"
    if [ -z "$release" ] || [ "$release" == 'all' ] ; then
        curl -sL "$TMUX_API_URL"
    elif [ "$release" == 'latest' ] ; then
        curl -sL "${TMUX_API_URL}/latest"
    else
        local query=".[] | select(.tag_name == \"${release}\")"
        curl -sL "${TMUX_API_URL}" | jq "$query" 2>/dev/null
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
    [ "$tag_name" != "$current_version" ] &&\
    {
        echo -e "\e[31mFAIL ($tag_name != $current_version)\e[0m"
        return 1
    }
    echo -e '\e[32mOK\e[0m'
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
        release_data="$(tmux_get_release "$TMUX_RELEASE")" ||\
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
    build_dir="$(mktemp -d 2>/dev/null)"
    __CLEANUP_TARGETS__+=("$build_dir")

    echo -ne "\e[34m[INFO ] Downloading Tmux \e[35m${tag_name} \e[34m... \e[0m"
    curl -sL "$location" | tar -xz -C "$build_dir" ||\
    {
        echo -e '\e[31mFAIL\e[0m'
        return 1
    }
    echo -e '\e[32mOK\e[0m'
    cd "$build_dir"/tmux-*

    echo -ne "\e[34m[INFO ] Building Tmux from source ... \e[0m"
    ./configure &>"$__STDERR__" &&\
    make &>"$__STDERR__" ||\
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

installer() {
    parse_opts "$@"
    check_depends

    [ "$INSTALL_TMUX" == 'true' ] &&\
        tmux_install

    [ -n "$INSTALL_FONTS" ] &&\
        nf_install_fonts "$INSTALL_FONTS"

    echo -e '\e[32m[OK   ] All processes complete\e[0m'
    return 0
}

trap 'echo -e "\e[31m[FATAL] Something went wrong\e[0m" ; cleanup ; exit 1' ERR
trap 'cleanup ; exit 0' INT TERM HUP QUIT

installer "$@"

kill -TERM "$BASHPID"
