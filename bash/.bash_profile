if [ -f ~/.bashrc ]; then
   source ~/.bashrc
fi

if [ -f ~/.bash_aliases ]; then
  source ~/.bash_aliases
fi

if [ -f ~/.git-completion.bash ]; then
	source ~/.git-completion.bash
fi
GIT_PS1_SHOWDIRTYSTATE=true
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

#\d date
#\h host name
#\n newline
#\s shellname
#\t time
#\u user
#\W \w current working dir \ fullpath


if [ -f /opt/local/etc/bash_completion ]; then
    . /opt/local/etc/bash_completion
fi

PS1='\[\033[32m\]\u\033[00m\]: \033[34m\]\W\033[31m\]$(__git_ps1)\[\033[00m\]\$ '
PS1="\[\033[G\]$PS1"

# This loads RVM into a shell session.
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"  DARKGRAY='\e[1;30m'

export PATH="/usr/local/bin:/usr/local/sbin:/usr/local/mysql/bin:$PATH"
export HISTFILESIZE=10000 #last 10,000 commands
export HISTSIZE=10000 #record last 10,000 commands per session
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"  # Load RVM into a shell session *as a function*
