use Irssi;
use strict;
use FileHandle;

use vars qw($VERSION %IRSSI***REMOVED***

$VERSION = "2.0";
%IRSSI = (
    authors     => 'John C. Vernaleo',
    contact     => 'john@netpurgatory.com',
    name        => 'tmux_away',
    description => 'set (un)away if tmux session is attached/detached',
    license     => 'GPL v2',
    url         => 'http://www.netpurgatory.com/tmux_away.html',
***REMOVED***

# tmux_away irssi module
#
# Written by Colin Didier <cdidier@cybione.org> and heavily based on
# screen_away irssi module version 0.9.7.1 written by Andreas 'ads' Scherbaum
# <ads@ufp.de>.
#
# Updated by John C. Vernaleo <john@netpurgatory.com> to handle tmux with
# named sessions and other code cleanup and forked as version 2.0.
#
# usage:
#
# put this script into your autorun directory and/or load it with
#  /SCRIPT LOAD <name>
#
# there are 5 settings available:
#
# /set tmux_away_active ON/OFF/TOGGLE
# /set tmux_away_repeat <integer>
# /set tmux_away_message <string>
# /set tmux_away_window <string>
# /set tmux_away_nick <string>
#
# active means that you will be only set away/unaway, if this
#   flag is set, default is ON
# repeat is the number of seconds, after the script will check the
#   tmux session status again, default is 5 seconds
# message is the away message sent to the server, default: not here ...
# window is a window number or name, if set, the script will switch
#   to this window, if it sets you away, default is '1'
# nick is the new nick, if the script goes away
#   will only be used it not empty


# variables
my $timer_name = undef;
my $away_status = 0;
my %old_nicks = (***REMOVED***
my %away = (***REMOVED***

# Register formats
Irssi::theme_register(
[
 'tmux_away_crap',
 '{line_start}{hilight ' . $IRSSI{'name'} . ':} $0'
]***REMOVED***

# try to find out if we are running in a tmux session
# (see if $ENV{TMUX} is set)
if (!defined($ENV{TMUX})) {
  # just return, we will never be called again
  Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'tmux_away_crap',
    "no tmux session!"***REMOVED***
  return;
}

my @args_env = split(',', $ENV{TMUX}***REMOVED***

# Get session name.  Must be connected for this to work, but since this either
# happens at startup or based on user command, should be okay.
my $tmux_session = `tmux display-message -p '#S'`;
chomp($tmux_session***REMOVED***

# register config variables
Irssi::settings_add_bool('misc', $IRSSI{'name'} . '_active', 1***REMOVED***
Irssi::settings_add_int('misc', $IRSSI{'name'} . '_repeat', 5***REMOVED***
Irssi::settings_add_str('misc', $IRSSI{'name'} . '_message', "not here..."***REMOVED***
Irssi::settings_add_str('misc', $IRSSI{'name'} . '_window', "1"***REMOVED***
Irssi::settings_add_str('misc', $IRSSI{'name'} . '_nick', ""***REMOVED***


# check, set or reset the away status
sub tmux_away {
  my ($status, @res***REMOVED***

  # only run, if activated
  if (Irssi::settings_get_bool($IRSSI{'name'} . '_active') != 1) {
    $away_status = 0;
***REMOVED*** else {
    if ($away_status == 0) {
      # display init message at first time
      Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'tmux_away_crap',
        "activating $IRSSI{'name'} (interval: " . Irssi::settings_get_int($IRSSI{'name'} . '_repeat') . " seconds)"***REMOVED***
      $away_status = 2;
  ***REMOVED***

    # get actual tmux session status
    @res = `tmux list-clients -t $tmux_session`;
    if (@res[0] =~ /^failed to connect to server/) {
      Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'tmux_away_crap',
        "error getting tmux session status."***REMOVED***
      return;
  ***REMOVED***
    $status = 1; # away, assumes the session is detached
    if ($#res != -1) {
	$status = 2; # unaway
  ***REMOVED***

    # unaway -> away
    if ($status == 1 and $away_status != 1) {
      if (length(Irssi::settings_get_str($IRSSI{'name'} . '_window')) > 0) {
        # if length of window is greater then 0, make this window active
        Irssi::command('window goto ' . Irssi::settings_get_str($IRSSI{'name'} . '_window')***REMOVED***
    ***REMOVED***
      Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'tmux_away_crap', "Set away"***REMOVED***
      my $message = Irssi::settings_get_str($IRSSI{'name'} . '_message'***REMOVED***
      if (length($message) == 0) {
        # we have to set a message or we wouldnt go away
        $message = "not here ...";
    ***REMOVED***
      foreach (Irssi::servers()) {
        if (!$_->{usermode_away}) {
	  # user isn't yet away
	  $away{$_->{'tag'}} = 0;
	  $_->command("AWAY " . ($_->{chat_type} ne 'SILC' ? "-one " : "") . "$message"***REMOVED***
	  if ($_->{chat_type} ne 'XMPP' and length(Irssi::settings_get_str($IRSSI{'name'} . '_nick')) > 0) {
            # only change if actual nick isn't already the away nick
            if (Irssi::settings_get_str($IRSSI{'name'} . '_nick') ne $_->{nick}) {
              # keep old nick
              $old_nicks{$_->{'tag'}} = $_->{nick***REMOVED***
              # set new nick
              $_->command("NICK " . Irssi::settings_get_str($IRSSI{'name'} . '_nick')***REMOVED***
          ***REMOVED***
        ***REMOVED***
      ***REMOVED*** else {
          # user is already away, remember this
          $away{$_->{'tag'}} = 1;
      ***REMOVED***
    ***REMOVED***
      $away_status = $status;

    # away -> unaway
  ***REMOVED*** elsif ($status == 2 and $away_status != 2) {
      # unset away
      Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'tmux_away_crap', "Reset away"***REMOVED***
      foreach (Irssi::servers()) {
        if ($away{$_->{'tag'}} == 1) {
          # user was already away, don't reset away
          $away{$_->{'tag'}} = 0;
          next;
      ***REMOVED***
        $_->command("AWAY" . (($_->{chat_type} ne 'SILC') ? " -one" : "")) if ($_->{usermode_away}***REMOVED***
        if ($_->{chat_type} ne 'XMPP' and defined($old_nicks{$_->{'tag'}}) and length($old_nicks{$_->{'tag'}}) > 0) {
          # set old nick
          $_->command("NICK " . $old_nicks{$_->{'tag'}}***REMOVED***
          $old_nicks{$_->{'tag'}} = "";
      ***REMOVED***
    ***REMOVED***
      $away_status = $status;
  ***REMOVED***
***REMOVED***
  # but everytimes install a new timer
  register_tmux_away_timer(***REMOVED***
  return 0;
}

# remove old timer and install a new one
sub register_tmux_away_timer {
  if (defined($timer_name)) {
    Irssi::timeout_remove($timer_name***REMOVED***
***REMOVED***
  # add new timer with new timeout (maybe the timeout has been changed)
  $timer_name = Irssi::timeout_add(Irssi::settings_get_int($IRSSI{'name'} . '_repeat') * 1000, 'tmux_away', ''***REMOVED***
}

# init process
tmux_away(***REMOVED***
