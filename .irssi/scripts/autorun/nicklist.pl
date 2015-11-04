# for documentation: see http://wouter.coekaerts.be/site/irssi/nicklist

use Irssi;
use strict;
use IO::Handle; # for (auto)flush
use Fcntl; # for sysopen
use vars qw($VERSION %IRSSI***REMOVED***
$VERSION = '0.4.6';
%IRSSI = (
	authors     => 'Wouter Coekaerts',
	contact     => 'coekie@irssi.org',
	name        => 'nicklist',
	description => 'draws a nicklist to another terminal, or at the right of your irssi in the same terminal',
	license     => 'GPLv2',
	url         => 'http://wouter.coekaerts.be/irssi',
	changed     => '29/06/2004'
***REMOVED***

sub cmd_help {
	print ( <<EOF
Commands:
NICKLIST HELP
NICKLIST SCROLL <nr of lines>
NICKLIST SCREEN
NICKLIST FIFO
NICKLIST OFF
NICKLIST UPDATE

For help see: http://wouter.coekaerts.be/site/irssi/nicklist

in short:

1. FIFO MODE
- in irssi: /NICKLIST FIFO (only the first time, to create the fifo)
- in a shell, in a window where you want the nicklist: cat ~/.irssi/nicklistfifo
- back in irssi:
    /SET nicklist_heigth <height of nicklist>
    /SET nicklist_width <width of nicklist>
    /NICKLIST FIFO

2. SCREEN MODE
- start irssi inside screen ("screen irssi")
- /NICKLIST SCREEN
EOF
    ***REMOVED***
}

my $prev_lines = 0;            ***REMOVED*** of lines in previous written nicklist
my $scroll_pos = 0;                  # scrolling position
my $cursor_line;                     # line the cursor is currently on
my ($OFF, $SCREEN, $FIFO) = (0,1,2***REMOVED*** # modes
my $mode = $OFF;                     # current mode
my $need_redraw = 0;                 # nicklist needs redrawing
my $screen_resizing = 0;             # terminal is being resized
my $active_channel;                  # (REC)

my @nicklist=(***REMOVED***                     # array of hashes, containing the internal nicklist of the active channel
	# nick => realnick
	# mode =>
	my ($MODE_OP, $MODE_HALFOP, $MODE_VOICE, $MODE_NORMAL) = (0,1,2,3***REMOVED***
	# status =>
	my ($STATUS_NORMAL, $STATUS_JOINING, $STATUS_PARTING, $STATUS_QUITING, $STATUS_KICKED, $STATUS_SPLIT) = (0,1,2,3,4,5***REMOVED***
	# text => text to be printed
	# cmp => text used to compare (sort) nicks


# 'cached' settings
my ($screen_prefix, $irssi_width, @prefix_mode, @prefix_status, $height, $nicklist_width***REMOVED***

sub read_settings {
	($screen_prefix = Irssi::settings_get_str('nicklist_screen_prefix')) =~ s/\\e/\033/g;

	($prefix_mode[$MODE_OP] = Irssi::settings_get_str('nicklist_prefix_mode_op')) =~ s/\\e/\033/g;
	($prefix_mode[$MODE_HALFOP] = Irssi::settings_get_str('nicklist_prefix_mode_halfop')) =~ s/\\e/\033/g;
	($prefix_mode[$MODE_VOICE] = Irssi::settings_get_str('nicklist_prefix_mode_voice')) =~ s/\\e/\033/g;
	($prefix_mode[$MODE_NORMAL] = Irssi::settings_get_str('nicklist_prefix_mode_normal')) =~ s/\\e/\033/g;
	
	if ($mode != $SCREEN) {
		$height = Irssi::settings_get_int('nicklist_height'***REMOVED***
	}
	my $new_nicklist_width = Irssi::settings_get_int('nicklist_width'***REMOVED***
	if ($new_nicklist_width != $nicklist_width && $mode == $SCREEN) {
		sig_terminal_resized(***REMOVED***
	}
	$nicklist_width = $new_nicklist_width;
}

sub update {
	read_settings(***REMOVED***
	make_nicklist(***REMOVED***
}

##################
##### OUTPUT #####
##################

### off ###

sub cmd_off {
	if ($mode == $SCREEN) {
		screen_stop(***REMOVED***
	} elsif ($mode == $FIFO) {
		fifo_stop(***REMOVED***
	}
}

### fifo ###

sub cmd_fifo_start {
	read_settings(***REMOVED***
	my $path = Irssi::settings_get_str('nicklist_fifo_path'***REMOVED***
	unless (-p $path) { # not a pipe
	    if (-e _) { # but a something else
	        die "$0: $path exists and is not a pipe, please remove it\n";
	  ***REMOVED*** else {
	        require POSIX;
	        POSIX::mkfifo($path, 0666) or die "can\'t mkfifo $path: $!";
		Irssi::print("Fifo created. Start reading it (\"cat $path\") and try again."***REMOVED***
		return;
	  ***REMOVED***
	}
	if (!sysopen(FIFO, $path, O_WRONLY | O_NONBLOCK)) { # or die "can't write $path: $!";
		Irssi::print("Couldn\'t write to the fifo ($!). Please start reading the fifo (\"cat $path\") and try again."***REMOVED***
		return;
	}
	FIFO->autoflush(1***REMOVED***
	print FIFO "\033[2J\033[1;1H"; # erase screen & jump to 0,0
	$cursor_line = 0;
	if ($mode == $SCREEN) {
		screen_stop(***REMOVED***
	}
	$mode = $FIFO;
	make_nicklist(***REMOVED***
}

sub fifo_stop {
	close FIFO;
	$mode = $OFF;
	Irssi::print("Fifo closed."***REMOVED***
}

### screen ###

sub cmd_screen_start {
	if (!defined($ENV{'STY'})) {
		Irssi::print 'screen not detected, screen mode only works inside screen';
		return;
	}
	read_settings(***REMOVED***
	if ($mode == $SCREEN) {return;}
	if ($mode == $FIFO) {
		fifo_stop(***REMOVED***
	}
	$mode = $SCREEN;
	Irssi::signal_add_last('gui print text finished', \&sig_gui_print_text_finished***REMOVED***
	Irssi::signal_add_last('gui page scrolled', \&sig_page_scrolled***REMOVED***
	Irssi::signal_add('terminal resized', \&sig_terminal_resized***REMOVED***
	screen_size(***REMOVED***
	make_nicklist(***REMOVED***
}

sub screen_stop {
	$mode = $OFF;
	Irssi::signal_remove('gui print text finished', \&sig_gui_print_text_finished***REMOVED***
	Irssi::signal_remove('gui page scrolled', \&sig_page_scrolled***REMOVED***
	Irssi::signal_remove('terminal resized', \&sig_terminal_resized***REMOVED***
	system 'screen -x '.$ENV{'STY'}.' -X fit';
}

sub screen_size {
	if ($mode != $SCREEN) {
		return;
	}
	$screen_resizing = 1;
	# fit screen
	system 'screen -x '.$ENV{'STY'}.' -X fit';
	# get size (from perldoc -q size)
	my ($winsize, $row, $col, $xpixel, $ypixel***REMOVED***
	eval 'use Term::ReadKey; ($col, $row, $xpixel, $ypixel) = GetTerminalSize';
	#	require Term::ReadKey 'GetTerminalSize';
	#	($col, $row, $xpixel, $ypixel) = Term::ReadKey::GetTerminalSize;
	#***REMOVED***
	if ($@) { # no Term::ReadKey, try the ugly way
		eval {
			require 'sys/ioctl.ph';
			# without this reloading doesn't work. workaround for some unknown bug
			do 'asm/ioctls.ph';
		***REMOVED***
		
		# ugly way not working, let's try something uglier, the dg-hack(tm) (constant for linux only?)
		if($@) { no strict 'refs'; *TIOCGWINSZ = sub { return 0x5413 } }
		
		unless (defined &TIOCGWINSZ) {
			die "Term::ReadKey not found, and ioctl 'workaround' failed. Install the Term::ReadKey perl module to use screen mode.\n";
		}
		open(TTY, "+</dev/tty") or die "No tty: $!";
		unless (ioctl(TTY, &TIOCGWINSZ, $winsize='')) {
			die "Term::ReadKey not found, and ioctl 'workaround' failed ($!). Install the Term::ReadKey perl module to use screen mode.\n";
		}
		close(TTY***REMOVED***
		($row, $col, $xpixel, $ypixel) = unpack('S4', $winsize***REMOVED***
	}
	
	# set screen width
	$irssi_width = $col-$nicklist_width-1;
	$height = $row-1;
	
	# on some recent systems, "screen -X fit; screen -X width -w 50" doesn't work, needs a sleep in between the 2 commands
	# so we wait a second before setting the width
	Irssi::timeout_add_once(1000, sub {
		my ($new_irssi_width) = @_;
		system 'screen -x '.$ENV{'STY'}.' -X width -w ' . $new_irssi_width;
		# and then we wait another second for the resizing, and then redraw.
		Irssi::timeout_add_once(1000,sub {$screen_resizing = 0; redraw()}, []***REMOVED***
	}, $irssi_width***REMOVED***
}

sub sig_terminal_resized {
	if ($screen_resizing) {
		return;
	}
	$screen_resizing = 1;
	Irssi::timeout_add_once(1000,\&screen_size,[]***REMOVED***
}


### both ###

sub nicklist_write_start {
	if ($mode == $SCREEN) {
		print STDERR "\033P\033[s\033\\"; # save cursor
	}
}

sub nicklist_write_end {
	if ($mode == $SCREEN) {
		print STDERR "\033P\033[u\033\\"; # restore cursor
	}
}

sub nicklist_write_line {
	my ($line, $data) = @_;
	if ($mode == $SCREEN) {
		print STDERR "\033P\033[" . ($line+1) . ';'. ($irssi_width+1) .'H'. $screen_prefix . $data . "\033\\";
	} elsif ($mode == $FIFO) {
		$data = "\033[m$data"; # reset color
		if ($line == $cursor_line+1) {
			$data = "\n$data"; # next line
		} elsif ($line == $cursor_line) {
			$data = "\033[1G".$data; # back to beginning of line
		} else {
			$data = "\033[".($line+1).";0H".$data; # jump
		}
		$cursor_line=$line;
		print(FIFO $data) or fifo_stop(***REMOVED***
	}
}

# recalc the text of the nicklist item
sub calc_text {
	my ($nick) = @_;
	my $tmp = $nicklist_width-3;
	(my $text = $nick->{'nick'}) =~ s/^(.{$tmp})..+$/$1\033[34m~\033[m/;
	$nick->{'text'} = $prefix_mode[$nick->{'mode'}] . $text . (' ' x ($nicklist_width-length($nick->{'nick'})-1)***REMOVED***
	$nick->{'cmp'} = $nick->{'mode'}.lc($nick->{'nick'}***REMOVED***
}

# redraw the given nick (nr) if it is visible
sub redraw_nick_nr {
	my ($nr) = @_;
	my $line = $nr - $scroll_pos;
	if ($line >= 0 && $line < $height) {
		nicklist_write_line($line, $nicklist[$nr]->{'text'}***REMOVED***
	}
}

# nick was inserted, redraw area if necessary
sub draw_insert_nick_nr {
	my ($nr) = @_;
	my $line = $nr - $scroll_pos;
	if ($line < 0) { # nick is inserted above visible area
		$scroll_pos++; # 'scroll' down :)
	} elsif ($line < $height) { # line is visible
		if ($mode == $SCREEN) {
			need_redraw(***REMOVED***
		} elsif ($mode == $FIFO) {
			my $data = "\033[m\033[L". $nicklist[$nr]->{'text'***REMOVED*** # reset color & insert line & write nick
			if ($line == $cursor_line) {
				$data = "\033[1G".$data; # back to beginning of line
			} else {
				$data = "\033[".($line+1).";1H".$data; # jump
			}
			$cursor_line=$line;
			print(FIFO $data) or fifo_stop(***REMOVED***
			if ($prev_lines < $height) {
				$prev_lines++; # the nicklist has one line more
			}
		}
	}
}

sub draw_remove_nick_nr {
	my ($nr) = @_;
	my $line = $nr - $scroll_pos;
	if ($line < 0) { # nick removed above visible area
		$scroll_pos--; # 'scroll' up :)
	} elsif ($line < $height) { # line is visible
		if ($mode == $SCREEN) {
			need_redraw(***REMOVED***
		} elsif ($mode == $FIFO) {
			#my $data = "\033[m\033[L[i$line]". $nicklist[$nr]->{'text'***REMOVED*** # reset color & insert line & write nick
			my $data = "\033[M"; # delete line
			if ($line != $cursor_line) {
				$data = "\033[".($line+1)."d".$data; # jump
			}
			$cursor_line=$line;
			print(FIFO $data) or fifo_stop(***REMOVED***
			if (@nicklist-$scroll_pos >= $height) {
				redraw_nick_nr($scroll_pos+$height-1***REMOVED***
			}
		}
	}
}

# redraw the whole nicklist
sub redraw {
	$need_redraw = 0;
	#make_nicklist(***REMOVED***
	nicklist_write_start(***REMOVED***
	my $line = 0;
	### draw nicklist ###
	for (my $i=$scroll_pos;$line < $height && $i < @nicklist; $i++) {
		nicklist_write_line($line++, $nicklist[$i]->{'text'}***REMOVED***
	}

	### clean up other lines ###
	my $real_lines = $line;
	while($line < $prev_lines) {
		nicklist_write_line($line++,' ' x $nicklist_width***REMOVED***
	}
	$prev_lines = $real_lines;
	nicklist_write_end(***REMOVED***
}

# redraw (with little delay to avoid redrawing to much)
sub need_redraw {
	if(!$need_redraw) {
		$need_redraw = 1;
		Irssi::timeout_add_once(10,\&redraw,[]***REMOVED***
	}
}

sub sig_page_scrolled {
	$prev_lines = $height; # we'll need to redraw everything if he scrolled up
	need_redraw;
}

# redraw (with delay) if the window is visible (only in screen mode)
sub sig_gui_print_text_finished {
	if ($need_redraw) { # there's already a redraw 'queued'
		return;
	}
	my $window = @_[0];
	if ($window->{'refnum'} == Irssi::active_win->{'refnum'} || Irssi::settings_get_str('nicklist_screen_split_windows') eq '*') {
		need_redraw;
		return;
	}
	foreach my $win (split(/[ ,]/, Irssi::settings_get_str('nicklist_screen_split_windows'))) {
		if ($window->{'refnum'} == $win || $window->{'name'} eq $win) {
			need_redraw;
			return;
		}
	}
}

####################
##### NICKLIST #####
####################

# returns the position of the given nick(as string) in the (internal) nicklist
sub find_nick {
	my ($nick) = @_;
	for (my $i=0;$i < @nicklist; $i++) {
		if ($nicklist[$i]->{'nick'} eq $nick) {
			return $i;
		}
	}
	return -1;
}

# find position where nick should be inserted into the list
sub find_insert_pos {
	my ($cmp)= @_;
	for (my $i=0;$i < @nicklist; $i++) {
		if ($nicklist[$i]->{'cmp'} gt $cmp) {
			return $i;
		}
	}
	return scalar(@nicklist***REMOVED*** #last
}

# make the (internal) nicklist (@nicklist)
sub make_nicklist {
	@nicklist = (***REMOVED***
	$scroll_pos = 0;

	### get & check channel ###
	my $channel = Irssi::active_win->{active***REMOVED***

	if (!$channel || (ref($channel) ne 'Irssi::Irc::Channel' && ref($channel) ne 'Irssi::Silc::Channel' && ref($channel) ne 'Irssi::Xmpp::Channel') || $channel->{'type'} ne 'CHANNEL' || ($channel->{chat_type} ne 'SILC' && !$channel->{'names_got'}) ) {
		$active_channel = undef;
		# no nicklist
	} else {
		$active_channel = $channel;
		### make nicklist ###
		my $thisnick;
		foreach my $nick (sort {(($a->{'op'}?'1':$a->{'halfop'}?'2':$a->{'voice'}?'3':'4').lc($a->{'nick'}))
		                    cmp (($b->{'op'}?'1':$b->{'halfop'}?'2':$b->{'voice'}?'3':'4').lc($b->{'nick'}))} $channel->nicks()) {
			$thisnick = {'nick' => $nick->{'nick'}, 'mode' => ($nick->{'op'}?$MODE_OP:$nick->{'halfop'}?$MODE_HALFOP:$nick->{'voice'}?$MODE_VOICE:$MODE_NORMAL)***REMOVED***
			calc_text($thisnick***REMOVED***
			push @nicklist, $thisnick;
		}
	}
	need_redraw(***REMOVED***
}

# insert nick(as hash) into nicklist
# pre: cmp has to be calculated
sub insert_nick {
	my ($nick) = @_;
	my $nr = find_insert_pos($nick->{'cmp'}***REMOVED***
	splice @nicklist, $nr, 0, $nick;
	draw_insert_nick_nr($nr***REMOVED***
}

# remove nick(as nr) from nicklist
sub remove_nick {
	my ($nr) = @_;
	splice @nicklist, $nr, 1;
	draw_remove_nick_nr($nr***REMOVED***
}

###################
##### ACTIONS #####
###################

# scroll the nicklist, arg = number of lines to scroll, positive = down, negative = up
sub cmd_scroll {
	if (!$active_channel) { # not a channel active
		return;
	}
	my @nicks=Irssi::active_win->{active}->nicks;
	my $nick_count = scalar(@nicks)+0;
	my $channel = Irssi::active_win->{active***REMOVED***
	if (!$channel || $channel->{type} ne 'CHANNEL' || !$channel->{names_got} || $nick_count <= Irssi::settings_get_int('nicklist_height')) {
		return;
	}
	$scroll_pos += @_[0];

	if ($scroll_pos > $nick_count - $height) {
		$scroll_pos = $nick_count - $height;
	}
	if ($scroll_pos <= 0) {
		$scroll_pos = 0;
	}
	need_redraw(***REMOVED***
}

sub is_active_channel {
	my ($server,$channel) = @_; # (channel as string)
	return ($server && $server->{'tag'} eq $active_channel->{'server'}->{'tag'} && $server->channel_find($channel) && $active_channel && $server->channel_find($channel)->{'name'} eq $active_channel->{'name'}***REMOVED***
}

sub sig_channel_wholist { # this is actualy a little late, when the names are received would be better
	my ($channel) = @_;
	if (Irssi::active_win->{'active'} && Irssi::active_win->{'active'}->{'name'} eq $channel->{'name'}) { # the channel joined is active
		make_nicklist
	}
}

sub sig_join {
	my ($server,$channel,$nick,$address) = @_;
	if (!is_active_channel($server,$channel)) {
		return;
	}
	my $newnick = {'nick' => $nick, 'mode' => $MODE_NORMAL***REMOVED***
	calc_text($newnick***REMOVED***
	insert_nick($newnick***REMOVED***
}

sub sig_kick {
	my ($server, $channel, $nick, $kicker, $address, $reason) = @_;
	if (!is_active_channel($server,$channel)) {
		return;
	}
	my $nr = find_nick($nick***REMOVED***
	if ($nr == -1) {
		Irssi::print("nicklist warning: $nick was kicked from $channel, but not found in nicklist"***REMOVED***
	} else {
		remove_nick($nr***REMOVED***
	}
}

sub sig_part {
	my ($server,$channel,$nick,$address, $reason) = @_;
	if (!is_active_channel($server,$channel)) {
		return;
	}
	my $nr = find_nick($nick***REMOVED***
	if ($nr == -1) {
		Irssi::print("nicklist warning: $nick has parted $channel, but was not found in nicklist"***REMOVED***
	} else {
		remove_nick($nr***REMOVED***
	}

}

sub sig_quit {
	my ($server,$nick,$address, $reason) = @_;
	if ($server->{'tag'} ne $active_channel->{'server'}->{'tag'}) {
		return;
	}
	my $nr = find_nick($nick***REMOVED***
	if ($nr != -1) {
		remove_nick($nr***REMOVED***
	}
}

sub sig_nick {
	my ($server, $newnick, $oldnick, $address) = @_;
	if ($server->{'tag'} ne $active_channel->{'server'}->{'tag'}) {
		return;
	}
	my $nr = find_nick($oldnick***REMOVED***
	if ($nr != -1) { # if nick was found (nickchange is in current channel)
		my $nick = $nicklist[$nr];
		remove_nick($nr***REMOVED***
		$nick->{'nick'} = $newnick;
		calc_text($nick***REMOVED***
		insert_nick($nick***REMOVED***
	}
}

sub sig_mode {
	my ($channel, $nick, $setby, $mode, $type) = @_; # (nick and channel as rec)
	if ($channel->{'server'}->{'tag'} ne $active_channel->{'server'}->{'tag'} || $channel->{'name'} ne $active_channel->{'name'}) {
		return;
	}
	my $nr = find_nick($nick->{'nick'}***REMOVED***
	if ($nr == -1) {
		Irssi::print("nicklist warning: $nick->{'nick'} had mode set on $channel->{'name'}, but was not found in nicklist"***REMOVED***
	} else {
		my $nicklist_item = $nicklist[$nr];
		remove_nick($nr***REMOVED***
		$nicklist_item->{'mode'} = ($nick->{'op'}?$MODE_OP:$nick->{'halfop'}?$MODE_HALFOP:$nick->{'voice'}?$MODE_VOICE:$MODE_NORMAL***REMOVED***
		calc_text($nicklist_item***REMOVED***
		insert_nick($nicklist_item***REMOVED***
	}
}

##### command binds #####
Irssi::command_bind 'nicklist' => sub {
    my ( $data, $server, $item ) = @_;
    $data =~ s/\s+$//g;
    Irssi::command_runsub ('nicklist', $data, $server, $item ) ;
***REMOVED***
Irssi::signal_add_first 'default command nicklist' => sub {
	# gets triggered if called with unknown subcommand
	cmd_help(***REMOVED***
***REMOVED***
Irssi::command_bind('nicklist update',\&update***REMOVED***
Irssi::command_bind('nicklist help',\&cmd_help***REMOVED***
Irssi::command_bind('nicklist scroll',\&cmd_scroll***REMOVED***
Irssi::command_bind('nicklist fifo',\&cmd_fifo_start***REMOVED***
Irssi::command_bind('nicklist screen',\&cmd_screen_start***REMOVED***
Irssi::command_bind('nicklist screensize',\&screen_size***REMOVED***
Irssi::command_bind('nicklist off',\&cmd_off***REMOVED***

##### signals #####
Irssi::signal_add_last('window item changed', \&make_nicklist***REMOVED***
Irssi::signal_add_last('window changed', \&make_nicklist***REMOVED***
Irssi::signal_add_last('channel wholist', \&sig_channel_wholist***REMOVED***
Irssi::signal_add_first('message join', \&sig_join***REMOVED*** # first, to be before ignores
Irssi::signal_add_first('message part', \&sig_part***REMOVED***
Irssi::signal_add_first('message kick', \&sig_kick***REMOVED***
Irssi::signal_add_first('message quit', \&sig_quit***REMOVED***
Irssi::signal_add_first('message nick', \&sig_nick***REMOVED***
Irssi::signal_add_first('message own_nick', \&sig_nick***REMOVED***
Irssi::signal_add_first('nick mode changed', \&sig_mode***REMOVED***

Irssi::signal_add('setup changed', \&read_settings***REMOVED***

##### settings #####
Irssi::settings_add_str('nicklist', 'nicklist_screen_prefix', '\e[m '***REMOVED***
Irssi::settings_add_str('nicklist', 'nicklist_prefix_mode_op', '\e[32m@\e[39m'***REMOVED***
Irssi::settings_add_str('nicklist', 'nicklist_prefix_mode_halfop', '\e[34m%\e[39m'***REMOVED***
Irssi::settings_add_str('nicklist', 'nicklist_prefix_mode_voice', '\e[33m+\e[39m'***REMOVED***
Irssi::settings_add_str('nicklist', 'nicklist_prefix_mode_normal', ' '***REMOVED***

Irssi::settings_add_int('nicklist', 'nicklist_width',11***REMOVED***
Irssi::settings_add_int('nicklist', 'nicklist_height',24***REMOVED***
Irssi::settings_add_str('nicklist', 'nicklist_fifo_path', Irssi::get_irssi_dir . '/nicklistfifo'***REMOVED***
Irssi::settings_add_str('nicklist', 'nicklist_screen_split_windows', ''***REMOVED***
Irssi::settings_add_str('nicklist', 'nicklist_automode', ''***REMOVED***

read_settings(***REMOVED***
if (uc(Irssi::settings_get_str('nicklist_automode')) eq 'SCREEN') {
	cmd_screen_start(***REMOVED***
} elsif (uc(Irssi::settings_get_str('nicklist_automode')) eq 'FIFO') {
	cmd_fifo_start(***REMOVED***
}
