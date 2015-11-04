# See http://wouter.coekaerts.be/site/irssi/mouse
# based on irssi mouse patch by mirage: http://darksun.com.pt/mirage/irssi/

# Copyright (C) 2005-2009  Wouter Coekaerts <wouter@coekaerts.be>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

use strict;
use Irssi qw(signal_emit settings_get_str active_win signal_stop settings_add_str settings_add_bool settings_get_bool signal_add signal_add_first***REMOVED***
use Math::Trig;

use vars qw($VERSION %IRSSI***REMOVED***

$VERSION = '1.0.0';
%IRSSI = (
	authors  	=> 'Wouter Coekaerts',
	contact  	=> 'wouter@coekaerts.be',
	name    	=> 'mouse',
	description 	=> 'control irssi using mouse clicks and gestures',
	license 	=> 'GPLv2 or later',
	url     	=> 'http://wouter.coekaerts.be/irssi/',
	changed  	=> '2009-05-16',
***REMOVED***

my @BUTTONS = ('', '_middle', '_right'***REMOVED***

my $mouse_xterm_status = -1; # -1:off 0,1,2:filling mouse_xterm_combo
my @mouse_xterm_combo = (3, 0, 0***REMOVED*** # 0:button 1:x 2:y
my @mouse_xterm_previous; # previous contents of mouse_xterm_combo

sub mouse_enable {
	print STDERR "\e[?1000h"; # start tracking 
}

sub mouse_disable {
	print STDERR "\e[?1000l"; # stop tracking 
}

# Handle mouse event (button press or release)
sub mouse_event {
	my ($b, $x, $y, $oldb, $oldx, $oldy) = @_;
	my ($xd, $yd***REMOVED***
	my ($distance, $angle***REMOVED***

	# uhm, in the patch the scrollwheel didn't work for me, but this does:
	if ($b == 64) {
		cmd("mouse_scroll_up"***REMOVED***
	} elsif ($b == 65) {
		cmd("mouse_scroll_down")
	}

	# proceed only if a button is being released
	return if ($b != 3***REMOVED***

	return unless (0 <= $oldb && $oldb <= 2***REMOVED***
	my $button = $BUTTONS[$oldb];

	# if it was a mouse click of the left button (press and release in the same position)
	if ($x == $oldx && $y == $oldy) {
		cmd("mouse" . $button . "_click"***REMOVED***
		return;
	}

	# otherwise, find mouse gestures
	$xd = $x - $oldx;
	$yd = -1 * ($y - $oldy***REMOVED***
	$distance = sqrt($xd*$xd + $yd*$yd***REMOVED***
	# ignore small gestures
	if ($distance < 3) {
		return;
	}
	$angle = asin($yd/$distance) * 180 / 3.14159265358979;
	if ($angle < 20 && $angle > -20 && $xd > 0) {
		if ($distance <= 40) {
			cmd("mouse" . $button . "_gesture_right"***REMOVED***
		} else {
			cmd("mouse" . $button . "_gesture_bigright"***REMOVED***
		}
	} elsif ($angle < 20 && $angle > -20 && $xd < 0) {
		if ($distance <= 40) {
			cmd("mouse" . $button . "_gesture_left"***REMOVED***
		} else {
			cmd("mouse" . $button . "_gesture_bigleft"***REMOVED***
		}
	} elsif ($angle > 40) {
		cmd("mouse" . $button . "_gesture_up"***REMOVED***
	} elsif ($angle < -40) {
		cmd("mouse" . $button . "_gesture_down"***REMOVED***
	}
}

# executes the command configured in the given setting
sub cmd
{
	my ($setting) = @_;
	signal_emit("send command", settings_get_str($setting), active_win->{'active_server'}, active_win->{'active'}***REMOVED***
}


signal_add_first("gui key pressed", sub {
	my ($key) = @_;
	if ($mouse_xterm_status != -1) {
		if ($mouse_xterm_status == 0 && ($mouse_xterm_previous[0] != $mouse_xterm_combo[0])) { # if combo is starting, and previous what not a move (button not changed)
			@mouse_xterm_previous = @mouse_xterm_combo;
		}
		$mouse_xterm_combo[$mouse_xterm_status] = $key-32;
		$mouse_xterm_status++;
		if ($mouse_xterm_status == 3) {
			$mouse_xterm_status = -1;
			# match screen coordinates
			$mouse_xterm_combo[1]--;
			$mouse_xterm_combo[2]--;
			mouse_event($mouse_xterm_combo[0], $mouse_xterm_combo[1], $mouse_xterm_combo[2], $mouse_xterm_previous[0], $mouse_xterm_previous[1], $mouse_xterm_previous[2]***REMOVED***
		}
		signal_stop(***REMOVED***
	}
}***REMOVED***

sub UNLOAD {
	mouse_disable(***REMOVED***
}

if ($ENV{"TERM"} !~ /^rxvt|screen|xterm(-color)?$/) {
	die "Your terminal doesn't seem to support this.";
}

mouse_enable(***REMOVED***

Irssi::command("/^bind meta-[M /mouse_xterm"***REMOVED*** # FIXME evil
Irssi::command_bind("mouse_xterm", sub {$mouse_xterm_status = 0;}***REMOVED***
Irssi::command_bind 'mouse' => sub {
	my ($data, $server, $item) = @_;
	$data =~ s/\s+$//g;
	Irssi::command_runsub('mouse', $data, $server, $item***REMOVED***
***REMOVED***

# temporarily disable mouse handling. Useful for copy-pasting without touching the keyboard (pressing shift)
Irssi::command_bind 'mouse tempdisable' => sub {
	my ($data, $server, $item) = @_;
	my $seconds = ($data eq '') ? 5 : $data; # optional argument saying how many seconds, defaulting to 5
	mouse_disable(***REMOVED***
	Irssi::timeout_add_once($seconds * 1000, 'mouse_enable', undef***REMOVED*** # turn back on after $second seconds
***REMOVED***

for my $button (@BUTTONS) {
	settings_add_str("lookandfeel", "mouse" . $button . "_click", "/mouse tempdisable 5"***REMOVED***
	settings_add_str("lookandfeel", "mouse" . $button . "_gesture_up", "/window last"***REMOVED***
	settings_add_str("lookandfeel", "mouse" . $button . "_gesture_down", "/window goto active"***REMOVED***
	settings_add_str("lookandfeel", "mouse" . $button . "_gesture_left", "/window prev"***REMOVED***
	settings_add_str("lookandfeel", "mouse" . $button . "_gesture_bigleft", "/eval window prev;window prev"***REMOVED***
	settings_add_str("lookandfeel", "mouse" . $button . "_gesture_right", "/window next"***REMOVED***
	settings_add_str("lookandfeel", "mouse" . $button . "_gesture_bigright", "/eval window next;window next"***REMOVED***
}

settings_add_str("lookandfeel", "mouse_scroll_up", "/scrollback goto -10"***REMOVED***
settings_add_str("lookandfeel", "mouse_scroll_down", "/scrollback goto +10"***REMOVED***
