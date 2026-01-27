#!/usr/bin/env bash

# github.com/tmux/tmux
# github.com/worldshredder
# https://gist.github.com/WorldShredder/7e85695196e03c80000bfb79d8195d93

######################################################################
##                                                                  ##
## - Downloads and installs the latest version of Tmux              ##
##                                                                  ##
## - Handles necessary compiler dependencies                        ##
##                                                                  ##
## - Install with: bash <(curl -sL GIST_URL/raw)                    ##
##                                                                  ##
## - Tmux release can be specified with -r or TMUX_RELEASE          ##
##                                                                  ##
##      bash <(curl -sL GIST_URL/raw) -r 3.6a                       ##
##      TMUX_RELEASE='3.6a' bash <(curl -sL GIST_URL/raw)           ##
##                                                                  ##
## - See -h|--help for for info                                     ##
##                                                                  ##
######################################################################

set -Eeo pipefail

__VERSION__='0.1.0'
GITHUB_API_URL="https://api.github.com/repos/tmux/tmux/releases"
TMUX_REPO_URL="https://github.com/tmux/tmux"
TMUX_BUILD_DIR=''

tmux_get_release() {
    local release="$1"
    if [ -z "$release" ] || [ "$release" == 'all' ] ; then
        curl -sSL "$GITHUB_API_URL"
    elif [ "$release" == 'latest' ] ; then
        curl -sSL "${GITHUB_API_URL}/latest"
    else
        curl -sSL "${GITHUB_API_URL}" | jq ".[] |\
            select(.tag_name == \"${release}\")"
    fi
}

tmux_list_releases() {
    local release_data="${1:-$(tmux_get_release)}"
    local ln_format='echo -ne "\e[35m${0}\t\e[36m$(date -d "$1" "+%F")\e[0m\n"'
    jq -r "[.[] | \"\(.tag_name)\t\(.assets[0].updated_at)\"] |\
        reverse | .[]" <<< "$release_data" |\
        xargs -n2 bash -c "$ln_format"
}

tmux_get_location() {
    local release="$1"
    local release_data="${2:-$(tmux_get_release "${1:-latest}")}"
    jq -r ". | .assets[0].browser_download_url" <<< "$release_data"
}

cleanup() {
    trap - ERR INT TERM HUP QUIT
    trap 'exit 1' ERR
    trap 'exit 0' INT TERM HUP QUIT
    while true ; do
        [ ! -d "$1" ] && break
        rm -rf "$1"
        shift
    done
}

print_help() {
cat << EOF
Usage: $0 [OPTIONS...]

Options:
  -l, --ls            List all available versions and release dates.
  -r, --release       Specificy a Tmux release to download and install.
  -v, --version       Print installer version.
  -h, --help          Print this help message.

https://github.com/WorldShredder
EOF
}

parse_opts() {
    set -Cu
    local short_opts long_opts params
    short_opts='lr:vh'
    long_opts='ls,tmux-release:,version,help'
    params="$(
        getopt -o "$short_opts" -l "$long_opts" --name "$0" -- "$@"
    )"
    eval set -- "$params" && set +Cu
    
    while true ; do
        case "$1" in
            -l|--ls)
                if ! which curl &>/dev/null ; then
                    echo -e "\e[31mError: Missing required package 'curl'"
                    exit 1
                fi
                tmux_list_releases
                exit 0 ;;
            -r|--release)
                TMUX_RELEASE="$2"
                shift 2 ;;
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
                echo -e "\e[31mInvalid option '$1'\e[0m"
                exit 1;;
        esac
    done
}
parse_opts "$@"

# Dependencies
declare -a REQUIRED_PKGS=('jq' 'curl' 'mktemp' 'xargs' 'bison' 'libevent-dev' 'libncurses-dev' 'make' 'gcc')
declare -a missing_pkgs
for pkg in "${REQUIRED_PKGS[@]}" ; do
    ! dpkg -s "$pkg" &>/dev/null && ! which "$pkg" &>/dev/null &&\
        missing_pkgs+=("$pkg")
done
if [ "${#missing_pkgs[@]}" -gt 0 ] ; then
    echo -e "\e[33mWarn: Missing required packages: ${missing_pkgs[*]}\e[0m"
    while read -n1 -p 'Install missing packages (Y/n) ' ; do
        echo
        case "$REPLY" in
            [yY]|'')
                sudo apt update
                sudo apt install -y ${missing_pkgs[*]} --no-install-recommends
                break ;;
            [nN])
                exit 1 ;;
            *)
                echo -e "\e[31mError: Invalid response '$REPLY'\e[0m" ;;
        esac
    done
fi

# Get tmux
[ -z "$TMUX_RELEASE" ] &&\
    TMUX_RELEASE='latest'

TMUX_BUILD_DIR="$(mktemp -d)"
trap "cleanup '$TMUX_BUILD_DIR'; exit 1" ERR
trap "cleanup '$TMUX_BUILD_DIR'; exit 0" INT TERM HUP QUIT

echo -e "\e[34mInfo: Installing tmux version: $TMUX_RELEASE\e[0m"
curl -sSL "$(tmux_get_location "$TMUX_RELEASE" |\
    grep -oE '^https://github\.com/.+')" | tar -xz -C "$TMUX_BUILD_DIR"

# Install tmux
cd "$TMUX_BUILD_DIR"/tmux-*
./configure && make
sudo make install

echo -e "\e[32mOK: Installation complete!\e[0m"
echo -e "\n  \e[35mVersion: $(tmux -V)\e[0m\n"

kill -TERM "$BASHPID"
