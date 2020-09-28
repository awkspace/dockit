#!/bin/bash
set -e

bash_complete_dir="/etc/bash_completion.d"
zsh_complete_dir="/usr/share/zsh/vendor-completions"

if [ ! $(id -u) -eq 0 ]
then
    echo "The installer requires root privileges."
    echo "If you'd like to run dockit as a user, add the bin/ directory to your PATH."
    exit 1
fi

dir=$(dirname "$0")

cp --update --verbose             $dir/bin/dockit /usr/local/bin/dockit
cp --update --verbose --recursive $dir/lib/dockit /usr/local/lib

#   Ensure that docker is installed and you are part of the docker group.
#   This command will add you to the docker group:
#   $usermod -a -G docker myusername"
if command -v bash   &> /dev/null \
    && command -v docker &> /dev/null \
    && id -nG "$(whoami)" | grep -qw "docker"
then
    mkdir -p "$bash_complete_dir"
    cp --update --verbose misc/dockit.bashcompletion "$bash_complete_dir"/dockit
    echo "bash completion script installed"
else
    echo "bash completion script not installed"
fi

if command -v zsh    &> /dev/null \
    && command -v docker &> /dev/null \
    && id -nG "$(whoami)" | grep -qw "docker"
then
    mkdir -p "$zsh_complete_dir"
    cp --update --verbose misc/dockit.zshcompletion "$zsh_complete_dir"/_dockit
    echo "zsh completion script installed"
    echo -e "\nYou may need to include this line in your ~/.zshrc file\n"
    echo -e "    autoload bashcompinit && bashcompinit\n"
else
    echo "zsh completion script not installed"
fi
