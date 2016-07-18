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

export HISTFILESIZE=1000000
#record last 10,000 commands per session
export HISTSIZE=1000000
# When executing the same command twice or more in a row, only store it once.
export HISTCONTROL="ignoredups:erasedupes"
# Save Reload History after a command
export PROMPT_COMMAND="history -n; history -w; history -c; history -r; history -a;"prompt_command"; $PROMPT_COMMAND"
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

shopt -s histappend
shopt -s cmdhist
shopt -s cdspell
shopt -s dirspell

export PS1="\[\e[32;1m\]\u \[\e[33;1m\]\w\[\e[0;1;30m\] \[\e[31;1m\]\$(parse_git_branch)\[\e[34;1m\]\[\e[34;1m\]❯ \[\e[0m\]"

export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"

if [[ $platform != 'freebsd' || $platform != 'linux' ]]; then
  alias vim="/usr/local/bin/vim"
fi

eval "$(rbenv init -)"

test -e ${HOME}/.iterm2_shell_integration.bash && source ${HOME}/.iterm2_shell_integration.bash
