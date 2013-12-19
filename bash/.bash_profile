platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
  platform='linux'
elif [[ "$unamestr" == 'FreeBSD' ]]; then
  platform='freebsd'
fi

for file in ~/.{bash_aliases,git-completion.bash,~/.rbenv/completions/rbenv.bash}; do
  [ -r "$file" ] && source "$file"
done

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

export PROMPT_COMMAND="prompt_command"

if [ -f /opt/local/etc/bash_completion ]; then
    . /opt/local/etc/bash_completion
fi

# Git status for prompt
function parse_git_dirty {
  [[ $(git status --porcelain 2> /dev/null | tail -n1) != "" ]] && echo "*"
}

function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1$(parse_git_dirty)/"
}

#last 10,000 commands
export HISTFILESIZE=10000
#record last 10,000 commands per session
export HISTSIZE=10000
# When executing the same command twice or more in a row, only store it once.
export HISTCONTROL=ignoredups;

export PS1="\[\e[32;1m\]\u \[\e[33;1m\]\w\[\e[0;1;30m\] \[\e[31;1m\]\$(parse_git_branch)\[\e[34;1m\]\[\e[34;1m\]❯ \[\e[0m\]"

if [[ $platform == 'freebsd' ]]; then
  export PATH="/usr/local/Cellar/vim/7.4.052/bin:$PATH"
fi

export PATH="/usr/local/lib/nodei:$PATH"
export PATH="/usr/local/share/npm/bin:$PATH"
export PATH="$HOME/src/nicplus/node_modules/.bin:$PATH"
export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/mysql/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"

eval "$(rbenv init -)"
