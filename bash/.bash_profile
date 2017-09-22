platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
  platform='linux'
elif [[ "$unamestr" == 'FreeBSD' ]]; then
  platform='freebsd'
elif [[ "$unamestr" == 'Darwin' ]]; then
  platform='darwin'
fi

for file in ~/.{bash_aliases,git-completion.bash,~/.rbenv/completions/rbenv.bash}; do
  [ -r "$file" ] && source "$file"
done

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

#last directory automation
if [ -f ~/.lastdir ]; then
  cd "`cat ~/.lastdir`"
fi

export LASTDIR="/"

function prompt_command {
  pwd > ~/.lastdir
  newdir=`pwd`
  if [ ! "$LASTDIR" = "$newdir" ]; then
    \ls -t | head -7
  fi
  export LASTDIR=$newdir
}

if [ -f `brew --prefix`/etc/bash_completion ]; then
  . `brew --prefix`/etc/bash_completion
fi

# Git status for prompt
function parse_git_dirty {
  [[ $(git status --porcelain 2> /dev/null | tail -n1) != "" ]] && echo "*"
}

function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1$(parse_git_dirty)/"
}

HISTFILESIZE=50000000
#record last 10,000 commands per session
HISTSIZE=5000000
# When executing the same command twice or more in a row, only store it once.
HISTCONTROL=ignoredups:erasedupes
shopt -s histappend
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"
# Save Reload History after a command
PROMPT_COMMAND="history -n; history -w; history -c; history -r; $PROMPT_COMMAND"

shopt -s cmdhist
shopt -s cdspell
shopt -s dirspell

export PS1="\[\e[32;1m\]\u \[\e[33;1m\]\w\[\e[0;1;30m\] \[\e[31;1m\]\$(parse_git_branch)\[\e[34;1m\]\[\e[34;1m\]❯ \[\e[0m\]"

if [[ $platform != 'freebsd' || $platform != 'linux' ]]; then
  alias vim="/usr/local/bin/vim"
fi

# ruby
eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/bin:$PATH"

# gpg
if [ -f ~/.gnupg/.gpg-agent-info ] && [ -n "$(pgrep gpg-agent)" ]; then
    source ~/.gnupg/.gpg-agent-info
    export GPG_AGENT_INFO
    GPG_TTY=$(tty)
    export GPG_TTY
  else
    eval $(gpg-agent --daemon --write-env-file ~/.gnupg/.gpg-agent-info)
fi

source ~/.iterm2_shell_integration.bash
