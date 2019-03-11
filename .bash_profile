#!/bin/bash

platform='unknown'
unamestr=$(uname)
if [[ "$unamestr" == 'Linux' ]]; then
	platform='linux'
elif [[ "$unamestr" == 'FreeBSD' ]]; then
	platform='freebsd'
elif [[ "$unamestr" == 'Darwin' ]]; then
	platform='darwin'
fi

# completions
for file in ~/.{bash_aliases,git-completion.bash,~/.rbenv/completions/rbenv.bash}; do
	# shellcheck source=/dev/null
	[ -r "$file" ] && source "$file"
done

# last directory automation
if [ -f ~/.lastdir ]; then
	cd "$(cat ~/.lastdir)" 2>/dev/null
fi

export LASTDIR="/"

function store_last_dir() {
	pwd >~/.lastdir
	newdir=$(pwd)
	if [ ! "$LASTDIR" = "$newdir" ]; then
		# shellcheck disable=2012
		ls -Art | tail -n 7
	fi
	export LASTDIR=$newdir
}

if [ -f "$(brew --prefix)/etc/bash_completion" ]; then
	# shellcheck source=/dev/null
	. "$(brew --prefix)/etc/bash_completion"
fi

# Git status for prompt
function parse_git_dirty() {
	[[ $(git status --porcelain 2>/dev/null | tail -n1) != "" ]] && echo "*"
}

function parse_git_branch() {
	git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e "s/* \\(.*\\)/\\1$(parse_git_dirty)/"
}

HISTFILESIZE=50000000
# record last 10,000 commands per session
HISTSIZE=5000000
# When executing the same command twice or more in a row, only store it once.
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"
# Save Reload History after a command
PROMPT_COMMAND="history -n; history -w; history -c; history -r; store_last_dir $PROMPT_COMMAND"

shopt -s cmdhist
shopt -s cdspell
shopt -s dirspell

export PS1="\[\e[32;1m\]\u \[\e[33;1m\]\w\[\e[0;1;30m\] \[\e[31;1m\]\$(parse_git_branch)\[\e[34;1m\]\[\e[34;1m\]❯ \[\e[0m\]"

if [[ $platform != 'freebsd' ]] || [[ $platform != 'linux' ]]; then
	alias vim="/usr/local/bin/vim"
fi

# gpg
# Avoid issues with `gpg` as installed via Homebrew.
# https://stackoverflow.com/a/42265848/96656
gpg_tty=$(tty)
export GPG_TTY=$gpg_tty

if [ -f ~/.gnupg/.gpg-agent-info ] && [ -n "$(pgrep gpg-agent)" ]; then
	source ~/.gnupg/.gpg-agent-info
	export GPG_AGENT_INFO
else
	eval $(gpg-agent --daemon --pinentry-program /usr/local/bin/pinentry-mac)
fi

# iterm
if [ -f ~/.iterm2_shell_integration.bash ]; then
	# shellcheck source=/dev/null
	source ~/.iterm2_shell_integration.bash
fi

# unison
alias unison='unison -ui text'
function unison_update() {
	if [[ $(whoami) == "aaroncrespo" ]]; then
		unison home
	else
		unison work
	fi
}

# ruby
eval "$(rbenv init -)"

export PATH="$HOME/.rbenv/bin:$PATH"

# rust
export PATH="$HOME/.cargo/bin:$PATH"

# go
export PATH="$(go env GOPATH 2>/dev/null)/bin:$PATH"
