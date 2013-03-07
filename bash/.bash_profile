for file in ~/.{bash_aliases,git-completion.bash***REMOVED*** do
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
  [[ $(git status 2> /dev/null | tail -n1) != "nothing to commit (working directory clean)" ]] && echo "*"
}

function parse_git_branch {
  git branch --no-color 2> /dev/null \
  | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1 /"
  #| sed -e '/^[^*]/d' -e "s/* \(.*\)/\1$(parse_git_dirty)/"
}

export PS1="\[\e[32;1m\]\u \[\e[33;1m\]\w\[\e[0;1;30m\] \[\e[31;1m\]\$(parse_git_branch)\[\e[34;1m\]\[\e[34;1m\]❯ \[\e[0m\]"

export NODE="/usr/local/lib/node"
export NPM="/usr/local/share/npm/bin"
export NIC_PLUS_NODE="$HOME/src/nicplus/node_modules/.bin"
export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/mysql/bin:$NIC_PLUS_NODE:$NODE:$NPMi:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"

eval "$(rbenv init -)"

export HISTFILESIZE=10000 #last 10,000 commands
export HISTSIZE=10000 #record last 10,000 commands per session
