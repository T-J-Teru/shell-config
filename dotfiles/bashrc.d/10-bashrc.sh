# .bashrc

#======================================#
#     GDB Testing Related Settings     #
#======================================#

# These are users that can be ssh'd to on the local machine without a
# password.  These users are used as part of GDB's full testing.
export GDB_HOST_USERNAME=remote-host
export GDB_TARGET_USERNAME=remote-target

#==========================#
#     Setup some paths     #
#==========================#

export MANPATH=${MANPATH}
export INFOPATH=${INFOPATH}:/usr/share/info
export PATH=${HOME}/bin:${HOME}/.python/bin:${PATH}

#===============================#
#           Perl Setup          #
#===============================#

export PERL_LOCAL_LIB_ROOT="$PERL_LOCAL_LIB_ROOT:$HOME/perl5";
export PERL_MB_OPT="--install_base $HOME/perl5";
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5";
export PERL5LIB="$HOME/perl5/lib/perl5:$PERL5LIB";
export PATH="$HOME/perl5/bin:$PATH";

#===============================#
#         Python Setup          #
#===============================#

export PYTHONUSERBASE=$HOME/.python

#=======================================#
#         Setup Default Modules         #
#=======================================#

export PACKAGE_MODULE_ROOT=$HOME/.software
MODULES_ROOT_DIRECTORY=${PACKAGE_MODULE_ROOT}/modules
if [ -d "${MODULES_ROOT_DIRECTORY}" ]
then
    DEFAULT_MODULE_LIST=""
    for versionfile in `find ${MODULES_ROOT_DIRECTORY} -name ".version" 2>/dev/null`
    do
        dir=`dirname $versionfile`
        modulename=`basename $dir`
        DEFAULT_MODULE_LIST="${DEFAULT_MODULE_LIST} ${modulename}"
    done
    # Not sure this 'purge' is a good idea.  This removes all loaded
    # modules so that the following load will result in a clean (just
    # the defaults) loaded in each new shell.  The problem is that if
    # I start a new termainl/shell from within an existing
    # terminal/shell then I'd probably expect the current state to
    # carry over.
    #
    # However, I added this because the session shell also picks up
    # the defaults at the point in time I start my session, then every
    # shell after that keeps the same defaults.  If I then change the
    # default for a particular package that default is loaded as well
    # as the original default.
    module purge
    module -s load ${DEFAULT_MODULE_LIST} &>/dev/null
else
    echo "No modules directory: ${MODULES_ROOT_DIRECTORY}"
fi

#=====================================#
#     Check for interactive shell     #
#=====================================#

case $- in
    *i*) ;;
    *) return ;;
esac

#======================================================#
#     Expand directories as part of tab comletion.     #
#======================================================#

shopt -s direxpand

#======================================#
#     flow control Ctrl-X for stop     #
#======================================#

## Not sure why this is here, this messes with GDB C-x C-a for
## entering TUI mode.
## Use 'stty -a' to view all the current setting.

## stty stop ^X

#=================#
#     aliases     #
#=================#
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

alias ls='ls --color=auto -CFv'
alias ll='ls -loF'
alias la='ls -loaF'
alias lt='ls --sort=time'
alias llt='ls -loF --sort=time'

alias tree='tree -v'

alias more=less

alias emacs-nw='emacs -nw'

alias getmail='getmail -nl'
alias grep='grep --color=auto -I --exclude="*~"'

alias pgrep='pgrep -f'
alias pkill='pkill -f'

alias id3v2='mid3v2'

[ -e "$HOME/.dircolors" ] && DIR_COLORS="$HOME/.dircolors"
[ -e "$DIR_COLORS" ] || DIR_COLORS=""
eval "`dircolors -b $DIR_COLORS`"

export LESS="-S -R -i -j5"
export LESSOPEN="||/usr/bin/lesspipe.sh %s"

export SHORT_HOSTNAME=$HOSTNAME

export EDITOR=emacs-nw
export PAGER=less
export CVSEDITOR=${EDITOR}

export LANG=en_GB.UTF-8

#======================================#
#    Protect agsint Ctrl-D mishaps     #
#======================================#

# With this set in bash I need to hit Ctrl-D 3 times in order to
# actually quit a shell with Ctrl-D.  The first two times will give a
# warning.
export IGNOREEOF=2

#====================================#
#    For warnings during startup     #
#====================================#

function warning ()
{
  MSG=$1
  echo -e "${COLOUR_RED}!! ${MSG}${COLOR_RESET}"
}

#======================#
#     Colour codes     #
#======================#

# Normal colour, change the 0 to a 1 for bold.
COLOUR_BLACK="\033[0;30m"
COLOUR_BLUE="\033[0;34m"
COLOUR_GREEN="\033[0;32m"
COLOUR_CYAN="\033[0;36m"
COLOUR_RED="\033[0;31m"
COLOUR_PURPLE="\033[0;35m"
COLOUR_BROWN="\033[0;33m"
COLOUR_GREY="\033[0;37m"

# Reset colour to normal foreground colour, and non bold.
COLOUR_RESET="\033[0m"

# Make text bold, normal foreground colour though.
TEXT_BOLD="\033[1m"

#==========================#
#     Setup the prompt     #
#==========================#

# Prompt is now BOLD & BLUE
PROMPT_COLOUR="\033[1;34m"

SCRIPT_PROMPT=""
if [ ! -z "$IN_SCRIPT" ]
then
  SCRIPT_PROMPT="<\[${COLOUR_RED}\]script\[${COLOUR_RESET}\]>"
fi

LOCK_DIR_PROMPT=""

# Load in special git prompt support (git-prompt.sh ships with git-core).
if [ -f /usr/share/git-core/contrib/completion/git-prompt.sh ]; then
    source /usr/share/git-core/contrib/completion/git-prompt.sh
fi

function set_prompt
{
    PS1="${LOCK_DIR_PROMPT}${SCRIPT_PROMPT}[\[${COLOUR_GREEN}\]\h\[${COLOUR_RESET}\]]\[${PROMPT_COLOUR}\]\W\[${COLOUR_RESET}\]"'$(__git_ps1 " (%s)")> '
    PS2="\[${PROMPT_COLOUR}\]>\[${COLOUR_RESET}\] "
}

set_prompt

WINDOW_TITLE=""

function prompt_command
{
  if [ -z "${WINDOW_TITLE}" ]
  then
      case $TERM in
          eterm*)
          ;;
          xterm*|screen)
              echo "-ne" "\033]0;`whoami`@${SHORT_HOSTNAME} ($PWD)\007"
              ;;
          *)
              ;;
      esac
  fi

  # Flush the history out.
  history -a
}
PROMPT_COMMAND=prompt_command

# Allow the window title to be changed. Either manually to a
# fixed string, or change everytime we switch directories.
function xtitle
{
  case $TERM in
      xterm*|screen)
          if [ "$1" == "" ]
          then
	      WINDOW_TITLE=""
          else
              echo -ne "\033]0;$1\007"
	      WINDOW_TITLE=$1
          fi
          ;;
      *)
          echo "Unable to change window title"
          return 1
          ;;
  esac
}

# Change to default, auto-updating, window title.
xtitle ""

#===========================#
#     Path Manipulation     #
#===========================#

# Take a directory, add it to the path.
#
# addpath [--end] [--quiet] [--] DIRECTORY
#
# With --end the DIRECTORY is added to the end of the PATH, otherwise
# the DIRECTORY is added to the beginning of the PATH.
#
# If DIRECTORY is not a valid path then an error is given and 1 is
# returned.  With --quiet the error is suppressed but 1 is still
# returned.
#
# After adding DIRECTORY to PATH successfully then 0 is returned.
#
# TODO: Maybe should remove duplicate entries from the path?
function addpath
{
    local QUIET=0
    local AT_END=0
    while true; do
        case "$1" in
            -e|--end)
                shift
                AT_END=1
                ;;
            -q|--quiet)
                shift
                QUIET=1
                ;;
            --)
                shift
                break
                ;;
            *)
                break
                ;;
        esac
    done

    local NP=$1

    # Check it's an actual directory.
    if [ -z "$NP" -o ! -d "$NP" ]
    then
        if [ ${QUIET} == 0 ]
        then
            if [ -z "$NP" ]
            then
                echo "addpath: missing new path"
            else
                echo "addpath: unknown path: $NP"
            fi
        fi
        return 1
    fi

    # Convert NP to an absolute path
    NP=$(cd ${NP} && pwd)

    if [ -z $PATH ]
    then
        PATH=$NP
    elif [ ${AT_END} == 1 ]
    then
        PATH=$PATH:$NP
    else
        PATH=$NP:$PATH
    fi
    return 0
}

addpath --quiet $HOME/bin
addpath --quiet /usr/lib64/ccache   # only if ccache is installed

function rmpath () {
    local target=$1
    target=$(cd $target && pwd)

    new_path=
    while IFS=: read -rd: dir; do
        if [ "$dir" != "$target" ]
        then
            if [ -z "$new_path" ]
            then
                new_path=$dir
            else
                new_path=$new_path:$dir
            fi
        fi
    done < <(printf %s: "$PATH")

    PATH=$new_path
    return 0
}

#==================================================#
#     Setup An EMAIL Environment Variable          #
#==================================================#

export EMAIL=`git config user.email 2>/dev/null`

[ -z "${EMAIL}" ] && \
    echo "* WARNING: Could not get a suitable email from git."

#==================================================#
#     Stuff for looking at the command history     #
#==================================================#

# Find all commands in my history that match a regexp.
function prev
{
  local REGEXP=$1
  local COUNT=$2

  # If regexp is numeric, but count is not, then
  # maybe the user has the arguments the wrong
  # way round. - Slap their ass and reverse the args
  function numeric
  {
    echo $1 | perl -e "if (<> =~ m/^\d+$/) {  exit 0; } exit 1;"
    if [ $? = 0 ]
    then
      echo "Number"
    else
      echo "Non-Number"
    fi
  }

  local s1=`numeric $REGEXP`
  local s2=`numeric $COUNT`

  if [ "$s1" == "Number" ]
  then
    if [ "$s2" != "Number" ]
    then
      local temp=${REGEXP}
      REGEXP=${COUNT}
     COUNT=${temp}
    fi
  fi
  # Function that actually _does_
  # the history search.
  function prev_guts
  {
      # 24/8/05: Used to use HISTSIZE which tells use how many lines there
      # are max in the history, but on some dumbass machines asking for more
      # lines than are actually in the history causes an error, so instead I
      # count how many lines are in the history, and then filter.
      # This would probably be better done without using fc at all not, but
      # I'm currently busy...
      local SIZE=`history | wc -l | tr -d " " 2>/dev/null`

      fc -ln -`expr $SIZE - 1` |  \
          perl -e "while (<>) { s/^\s+//; print if (m#${REGEXP}#); }"
  }

  # No regexp, defaults to _all_ history
  if [ "$REGEXP" == "" ]
  then
    REGEXP='.*'
  fi

  # Now do the search, truncating by count if required.
  if [ "$COUNT" == "" ]
  then
      prev_guts
  else
      prev_guts | tail -n $COUNT
  fi
}

# A command that will show me the last command that I executed.
alias lc="fc -ln -1 2>/dev/null | perl -pe 's/^\s+//'"

# Find the last command in my history that begins with some regexp.
function show-command
{
  local REGEXP=$1

  if [ ${REGEXP::1} != "^" ]
  then
      REGEXP="^$REGEXP"
  fi

  prev $REGEXP 1
};
alias sc='show-command'

#=====================================#
#     Special cd/bt functionality     #
#=====================================#
function custom-cd ()
{
  local show_pwd="N"

  local prevTen=`fc -ln -10 2>/dev/null | egrep -c " +cd"`;
  if [[ $prevTen -eq 0 ]];
  then
    show_pwd="Y"
  fi

  if [[ -z $@ ]]
  then
    builtin pushd $HOME >/dev/null 2>&1;
  else
    for dir in "$@"
    do
      if [[ -d $dir ]]
      then
        builtin pushd "$dir" >/dev/null 2>&1;
      else
        if [ $dir = "-" ]
        then
          local target=`dirs -l +1 2>/dev/null`
          popd +1  >/dev/null 2>&1
          builtin pushd "$target"  >/dev/null 2>&1
          show_pwd="Y"
        elif [[ ${dir:0:2} = ".." && ${#dir} > 2 ]]
        then
          echo ${dir} | grep -e '^\.*$' >/dev/null 2>/dev/null
          if [ $? == 0 ]
          then
            # This matches the pattern "\.\.\.+", so lets move
            # backwards up the dir tree by the (length($dir) - 2)
            # Record where we start.
            local initial_dir=${PWD}

            # Figure out where we're going to end up.
            for I in `seq 2 ${#dir}`
            do
              builtin cd ..
            done

            # Record where we end up.
            local final_dir=${PWD}

            # Move back to the starting position
            builtin cd "${initial_dir}"

            # And jump to the destination, adding to the stack.
            builtin pushd "${final_dir}" >/dev/null 2>&1

            # Lets show folk where they ended up
            show_pwd="Y"
          else
            echo "Unknown directory: $dir"
            return 1
          fi
        else
          echo "Unknown directory: $dir"
          return 1
        fi
      fi
    done
  fi

  if [[ ! -z "${CD_PLEASE_BE_SILENT}" ]]
  then
    show_pwd="N"
  fi

  if [ ! -t 1 ]
  then
      show_pwd="N"
  fi

  if [[ "$show_pwd" == "Y" ]]; then pwd; fi;
  return 0
}

function bt()
{
  OPTERR=0

  while getopts "rcm:M:hp" ARGUMENT
  do
    # -r: Reverse the list of directories
    if [ $ARGUMENT = "r" ]
    then
      echo "Reversing is not supported yet!"
      return 1
    fi

    # -c: Clears the list of previous directories
    if [ $ARGUMENT = "c" ]
    then
      dirs -c
      return 0
    fi

    # -m <pattern>: List directories matching pattern
    if [ $ARGUMENT = "m" ]
    then
      dirs -v | egrep $OPTARG
      return 0
    fi

    # -M <pattern>: As -m, but case insensitive.
    if [ $ARGUMENT = "M" ]
    then
      dirs -v | egrep -i $OPTARG
      return 0
    fi

    # -h parameter, provide some help
    if [ $ARGUMENT = "h" ]
    then
      echo "bt [-p|-r|-c|-h|-m <pattern>|-M <pattern>|<num>]"
      return 0
    fi

    # -p
    if [ $ARGUMENT = "p" ]
    then
      dirs -v
      return 0
    fi
  done

  # No options given, use the command line
  # number, or return the list.
  if [[ -z "$@" ]]
  then
    # Limit to at most 20 entries.
    dirs -v | perl -ne 'chomp; if (($. % 2) == 0) { print "\033[1m"; }  print $_,"\033[0m\n"' | head -n 20
  else
    # Check that $1 is a number
    local target=`dirs -l +$1 2>/dev/null`
    if [ ! -z "${target}" ]
    then
      custom-cd "${target}"
      return 0
    else
      echo "Invalid index: $1"
      return 1
    fi
  fi
}

function dir-locked()
{
  echo "Directory is currently locked at $PWD"
  echo "Use 'unlockdir' to change directory again."
}

alias cd='custom-cd'

function lockdir()
{
  alias cd='dir-locked';

  LOCK_DIR_PROMPT="<\[${COLOUR_RED}\]Locked\[${COLOUR_RESET}\]>"
  set_prompt
}

function unlockdir()
{
  alias cd='custom-cd';

  LOCK_DIR_PROMPT=""
  set_prompt
}

#=================================#
#     Simple version of watch     #
#=================================#

function monitor
{
  watch --interval=1 $@
}

#====================#
#     Pretty PWD     #
#====================#
# Take a string which could really be anything, but add the strings
# required for bash to add colour to it. Allows paths to take a
# uniform colour.
function colourize_path
{
  local PATH_TO_MANGLE=$1
  echo "${COLOUR_PURPLE}$PATH_TO_MANGLE${COLOUR_RESET}"
}

# Make PWDs stand out so we can see where we've been.
function pretty_pwd
{
    if [ -t 1 ]
    then
        echo -e PWD: `colourize_path "${PWD}"`
    else
        builtin pwd
    fi
}
alias pwd='pretty_pwd'


#======================================#
#     Add support for upto command     #
#======================================#

function upto()
{
  local PATTERN=$1

  if [ -z ${PATTERN} ]
  then
    echo "** No pattern supplied to upto!!"
    return 1
  fi

  local WORKER=$HOME/bin/upto_core.pl

  if [ ! -e ${WORKER} ]
  then
      echo -e "Failed to find the worker script: `colourize_path \"${WORKER}\"`"
      return 1
  fi

  DEST=`${WORKER} --pattern "${PATTERN}" --path "${PWD}"`

  # We get the empty list if nothing matches pattern.
  if [ -z ${DEST} ]
  then
    echo -e "!! Pattern not found: '${PATTERN}'";
    DEST=${PWD}
  fi

  if [ "${DEST}" != "${PWD}" ]
  then
    # Give a suitable message, and change to the new directory
    local DIR="${DEST}"
    echo -e "Jumping to: `colourize_path \"${DIR}\"`"
    CD_PLEASE_BE_SILENT=y cd ${DEST}
  else
    # Saves pushing needless directories onto the cd stack.
    local DIR="${PWD}"
    echo -e "Remaining in: `colourize_path \"${DIR}\"`"
  fi
}

# Mmmm, lazy boy.
alias jmp='upto'

#=============================================================#
# An escape command for when I'm stuck in a deleted directory #
#=============================================================#

# Due to the use of my custom-cd function, if I'm in a
# directory that gets deleted then trying to cd out of it will
# not work, bah!  This escape function gets we to the closest
# ancestor directory that still exists.

function escape ()
{
    ORIG=$PWD
    ORIG_TO_PRINT=$PWD

    builtin cd /

    while [ ! -d "$ORIG" ]
    do
        ORIG=`dirname "$ORIG"`
    done

    if [ "x$ORIG" == "x$ORIG_TO_PRINT" ]
    then
        echo -e "Reacquired: `colourize_path \"$ORIG_TO_PRINT\"`"
    else
        echo -e "Was in: `colourize_path \"$ORIG_TO_PRINT\"`"
        echo -e "Now in: `colourize_path \"$ORIG\"`"
    fi

    builtin cd "$ORIG"
}

#=========================================#
#       pgrep for my processes only       #
#=========================================#

function pgrep-me ()
{
    pgrep -U ${LOGNAME} $@
}

#=========================================#
#     Some sanity checks and warnings     #
#=========================================#

function tool_check ()
{
  TOOL=$1

  if [ "$(type -t ${TOOL})" == "" ]
  then
    warning "Missing command $TOOL"
  fi
}

#====================================================#
#     Configure the history into different files     #
#====================================================#

HISTSIZE=32768	     # save this many lines in the run-time history
unset HISTFILESIZE	     # no maximum size of history file
HISTFILE=$HOME/.hist/`uname -n`/`date +%Y%m%d-%H%M`-$$
[ -d $(dirname ${HISTFILE}) ] || mkdir -p $(dirname ${HISTFILE})
rm -f $HISTFILE   # Nuke old history for this PID.
touch $HISTFILE
LAST_CWD=$PWD
HISTCONTROL=ignoredups     # don't save history identical to previous lines
shopt -u histappend        # overwrite HISTFILE on exit instead of appending
unset TMOUT		     # no timed auto-logout
unset MAILCHECK
command_oriented_history=1 # save multi-line commands as a single line
set -o emacs		     # Emacs-style readline
set -o physical	     # do not follow symlinks when changing current dir
shopt -s checkwinsize      # check window after each cmd, update LINES/COLUMNS

# find things in previous history ( most recent 5 history files only )
function histfind ()
{
  n=5
  grep -rl -- "$1" ~/.hist | xargs ls -1tr \
    | tail -$n | xargs grep --color=always -- "$1" /dev/null | uniq
}

#===========================================#
#           Display The Weather             #
#===========================================#

function weather()
{
    # change Paris to your default location
    local request="wttr.in/${1-52.43,0.24}"
    [ "$(tput cols)" -lt 125 ] && request+='?n'
    curl -H "Accept-Language: ${LANG%_*}" --compressed "$request"
}

alias wttr=weather

#=======================================#
#     Custom git command completion     #
#=======================================#

# For help on adding command completion to custom git commands see:
#
# https://github.com/git/git/blob/master/contrib/completion/git-completion.bash
# https://stackoverflow.com/questions/41307313/custom-git-command-autocompletion

function _git_update_changelogs () {
    # Just offer the same choices as 'git rebase' does.
    _git_rebase "$@"
}

function _git_fstat () {
    # Just offer the same choices as 'git rebase' does.
    _git_rebase "$@"
}

#=====================================================================

# Local Variables:
# mode: sh
# End:
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
