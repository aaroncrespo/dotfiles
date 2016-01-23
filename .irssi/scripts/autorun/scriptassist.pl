# by Stefan "tommie" Tomanek
#
# scriptassist.pl


use strict;

use vars qw($VERSION %IRSSI***REMOVED***
$VERSION = '2003020803';
%IRSSI = (
    authors     => 'Stefan \'tommie\' Tomanek',
    contact     => 'stefan@pico.ruhr.de',
    name        => 'scriptassist',
    description => 'keeps your scripts on the cutting edge',
    license     => 'GPLv2',
    url         => 'http://irssi.org/scripts/',
    changed     => $VERSION,
    modules     => 'Data::Dumper LWP::UserAgent (GnuPG)',
    commands	=> "scriptassist"
***REMOVED***

use vars qw($forked %remote_db $have_gpg***REMOVED***

use Irssi 20020324;
use Data::Dumper;
use LWP::UserAgent;
use POSIX;

# GnuPG is not always needed
use vars qw($have_gpg @complist***REMOVED***
$have_gpg = 0;
eval "use GnuPG qw(:algo :trust***REMOVED***";
$have_gpg = 1 if not ($@***REMOVED***

sub show_help() {
    my $help = "scriptassist $VERSION
/scriptassist check
    Check all loaded scripts for new available versions
/scriptassist update <script|all>
    Update the selected or all script to the newest version
/scriptassist search <query>
    Search the script database
/scriptassist info <scripts>
    Display information about <scripts>
/scriptassist ratings <scripts>
    Retrieve the average ratings of the the scripts
/scriptassist top <num>
    Retrieve the first <num> top rated scripts
/scriptassist new <num>
    Display the newest <num> scripts
/scriptassist rate <script> <stars>
    Rate the script with a number of stars ranging from 0-5
/scriptassist contact <script>
    Write an email to the author of the script
    (Requires OpenURL)
/scriptassist cpan <module>
    Visit CPAN to look for missing Perl modules
    (Requires OpenURL)
/scriptassist install <script>
    Retrieve and load the script
/scriptassist autorun <script>
    Toggles automatic loading of <script>
";  
    my $text='';
    foreach (split(/\n/, $help)) {
        $_ =~ s/^\/(.*)$/%9\/$1%9/;
        $text .= $_."\n";
  ***REMOVED***
    print CLIENTCRAP &draw_box("ScriptAssist", $text, "scriptassist help", 1***REMOVED***
    #theme_box("ScriptAssist", $text, "scriptassist help", 1***REMOVED***
}

sub theme_box ($$$$) {
    my ($title, $text, $footer, $colour) = @_;
    Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'box_header', $title***REMOVED***
    foreach (split(/\n/, $text)) {
	Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'box_inside', $_***REMOVED***
  ***REMOVED***
    Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'box_footer', $footer***REMOVED***
}

sub draw_box ($$$$) {
    my ($title, $text, $footer, $colour) = @_;
    my $box = '';
    $box .= '%R,--[%n%9%U'.$title.'%U%9%R]%n'."\n";
    foreach (split(/\n/, $text)) {
        $box .= '%R|%n '.$_."\n";
  ***REMOVED***                                                                               $box .= '%R`--<%n'.$footer.'%R>->%n';
    $box =~ s/%.//g unless $colour;
    return $box;
}

sub call_openurl ($) {
    my ($url) = @_;
    no strict "refs";
    # check for a loaded openurl
    if ( %{ "Irssi::Script::openurl::" }) {
        &{ "Irssi::Script::openurl::launch_url" }($url***REMOVED***
  ***REMOVED*** else {
        print CLIENTCRAP "%R>>%n Please install openurl.pl";
  ***REMOVED***
    use strict;
}

sub bg_do ($) {
    my ($func) = @_; 
    my ($rh, $wh***REMOVED***
    pipe($rh, $wh***REMOVED***
    if ($forked) {
	print CLIENTCRAP "%R>>%n Please wait until your earlier request has been finished.";
	return;
  ***REMOVED***
    my $pid = fork(***REMOVED***
    $forked = 1;
    if ($pid > 0) {
	print CLIENTCRAP "%R>>%n Please wait...";
        close $wh;
        Irssi::pidwait_add($pid***REMOVED***
        my $pipetag;
        my @args = ($rh, \$pipetag, $func***REMOVED***
        $pipetag = Irssi::input_add(fileno($rh), INPUT_READ, \&pipe_input, \@args***REMOVED***
  ***REMOVED*** else {
	eval {
	    my @items = split(/ /, $func***REMOVED***
	    my %result;
	    my $ts1 = $remote_db{timestamp***REMOVED***
	    my $xml = get_scripts(***REMOVED***
	    my $ts2 = $remote_db{timestamp***REMOVED***
	    if (not($ts1 eq $ts2) && Irssi::settings_get_bool('scriptassist_cache_sources')) {
		$result{db} = $remote_db{db***REMOVED***
		$result{timestamp} = $remote_db{timestamp***REMOVED***
	  ***REMOVED***
	    if ($items[0] eq 'check') {
		$result{data}{check} = check_scripts($xml***REMOVED***
	  ***REMOVED*** elsif ($items[0] eq 'update') {
		shift(@items***REMOVED***
		$result{data}{update} = update_scripts(\@items, $xml***REMOVED***
	  ***REMOVED*** elsif ($items[0] eq 'search') {
		shift(@items***REMOVED***
		#$result{data}{search}{-foo} = 0;
		foreach (@items) {
		    $result{data}{search}{$_} = search_scripts($_, $xml***REMOVED***
		}
	  ***REMOVED*** elsif ($items[0] eq 'install') {
		shift(@items***REMOVED***
		$result{data}{install} = install_scripts(\@items, $xml***REMOVED***
	  ***REMOVED*** elsif ($items[0] eq 'debug') {
		shift(@items***REMOVED***
		$result{data}{debug} = debug_scripts(\@items***REMOVED***
	  ***REMOVED*** elsif ($items[0] eq 'ratings') {
		shift(@items***REMOVED***
		@items = @{ loaded_scripts() } if $items[0] eq "all";
		#$result{data}{rating}{-foo} = 1;
		my %ratings = %{ get_ratings(\@items, '') ***REMOVED***
		foreach (keys %ratings) {
		    $result{data}{rating}{$_}{rating} = $ratings{$_}->[0];
		    $result{data}{rating}{$_}{votes} = $ratings{$_}->[1];
		}
	  ***REMOVED*** elsif ($items[0] eq 'rate') {
		#$result{data}{rate}{-foo} = 1;
		$result{data}{rate}{$items[1]} = rate_script($items[1], $items[2]***REMOVED***
	  ***REMOVED*** elsif ($items[0] eq 'info') {
		shift(@items***REMOVED***
		$result{data}{info} = script_info(\@items***REMOVED***
	  ***REMOVED*** elsif ($items[0] eq 'echo') {
		$result{data}{echo} = 1;
	  ***REMOVED*** elsif ($items[0] eq 'top') {
		my %ratings = %{ get_ratings([], $items[1]) ***REMOVED***
		foreach (keys %ratings) {
                    $result{data}{rating}{$_}{rating} = $ratings{$_}->[0];
                    $result{data}{rating}{$_}{votes} = $ratings{$_}->[1];
              ***REMOVED***
	  ***REMOVED*** elsif ($items[0] eq 'new') {
		my $new = get_new($items[1]***REMOVED***
		$result{data}{new} = $new;
	  ***REMOVED*** elsif ($items[0] eq 'unknown') {
		my $cmd = $items[1];
		$result{data}{unknown}{$cmd} = get_unknown($cmd, $xml***REMOVED***
	  ***REMOVED***
	    my $dumper = Data::Dumper->new([\%result]***REMOVED***
	    $dumper->Purity(1)->Deepcopy(1)->Indent(0***REMOVED***
	    my $data = $dumper->Dump;
	    print($wh $data***REMOVED***
	***REMOVED***
	close($wh***REMOVED***
	POSIX::_exit(1***REMOVED***
  ***REMOVED***
}

sub get_unknown ($$) {
    my ($cmd, $db) = @_;
    foreach (keys %$db) {
	next unless defined $db->{$_}{commands***REMOVED***
	foreach my $item (split / /, $db->{$_}{commands}) {
	    return { $_ => $db->{$_} } if ($item =~ /^$cmd$/i***REMOVED***
	}
  ***REMOVED***
    return undef;
}

sub script_info ($) {
    my ($scripts) = @_;
    no strict "refs";
    my %result;
    my $xml = get_scripts(***REMOVED***
    foreach (@{$scripts}) {
	next unless (defined $xml->{$_.".pl"} || ( %{ 'Irssi::Script::'.$_.'::' } &&  %{ 'Irssi::Script::'.$_.'::IRSSI' })***REMOVED***
	$result{$_}{version} = get_remote_version($_, $xml***REMOVED***
	my @headers = ('authors', 'contact', 'description', 'license', 'source'***REMOVED***
	foreach my $entry (@headers) {
	    $result{$_}{$entry} = ${ 'Irssi::Script::'.$_.'::IRSSI' }{$entry***REMOVED***
	    if (defined $xml->{$_.".pl"}{$entry}) {
		$result{$_}{$entry} = $xml->{$_.".pl"}{$entry***REMOVED***
	  ***REMOVED***
	}
	if ($xml->{$_.".pl"}{signature_available}) {
	    $result{$_}{signature_available} = 1;
	}
	if (defined $xml->{$_.".pl"}{modules}) {
	    my $modules = $xml->{$_.".pl"}{modules***REMOVED***
	    #$result{$_}{modules}{-foo} = 1;
	    foreach my $mod (split(/ /, $modules)) {
		my $opt = ($mod =~ /\((.*)\)/)? 1 : 0;
		$mod = $1 if $1;
		$result{$_}{modules}{$mod}{optional} = $opt;
		$result{$_}{modules}{$mod}{installed} = module_exist($mod***REMOVED***
	  ***REMOVED***
	} elsif (defined ${ 'Irssi::Script::'.$_.'::IRSSI' }{modules}) {
	    my $modules = ${ 'Irssi::Script::'.$_.'::IRSSI' }{modules***REMOVED***
	    foreach my $mod (split(/ /, $modules)) {
		my $opt = ($mod =~ /\((.*)\)/)? 1 : 0;
		$mod = $1 if $1;
		$result{$_}{modules}{$mod}{optional} = $opt;
		$result{$_}{modules}{$mod}{installed} = module_exist($mod***REMOVED***
	  ***REMOVED***
	}
	if (defined $xml->{$_.".pl"}{depends}) {
	    my $depends = $xml->{$_.".pl"}{depends***REMOVED***
	    foreach my $dep (split(/ /, $depends)) {
		$result{$_}{depends}{$dep}{installed} = 1; #(defined ${ 'Irssi::Script::'.$dep }***REMOVED*** 
	  ***REMOVED***
	}
  ***REMOVED***
    return \%result;
}

sub rate_script ($$) {
    my ($script, $stars) = @_;
    my $ua = LWP::UserAgent->new(env_proxy=>1, keep_alive=>1, timeout=>30***REMOVED***
    $ua->agent('ScriptAssist/'.$VERSION***REMOVED***
    my $request = HTTP::Request->new('GET', 'http://ratings.irssi.de/irssirate.pl?&stars='.$stars.'&mode=rate&script='.$script***REMOVED***
    my $response = $ua->request($request***REMOVED***
    unless ($response->is_success() && $response->content() =~ /You already rated this script/) {
	return 1;
  ***REMOVED*** else {
	return 0;
  ***REMOVED***
}

sub get_ratings ($$) {
    my ($scripts, $limit) = @_;
    my $ua = LWP::UserAgent->new(env_proxy=>1, keep_alive=>1, timeout=>30***REMOVED***
    $ua->agent('ScriptAssist/'.$VERSION***REMOVED***
    my $script = join(',', @{$scripts}***REMOVED***
    my $request = HTTP::Request->new('GET', 'http://ratings.irssi.de/irssirate.pl?script='.$script.'&sort=rating&limit='.$limit***REMOVED***
    my $response = $ua->request($request***REMOVED***
    my %result;
    if ($response->is_success()) {
	foreach (split /\n/, $response->content()) {
	    if (/<tr><td><a href=".*?">(.*?)<\/a>/) {
		my $entry = $1;
		if (/"><\/td><td>([0-9.]+)<\/td><td>(.*?)<\/td><td>/) {
		    $result{$entry} = [$1, $2];
		}
	  ***REMOVED***
	}
  ***REMOVED***
    return \%result;
}

sub get_new ($) {
    my ($num) = @_;
    my $result;
    my $xml = get_scripts(***REMOVED***
    foreach (sort {$xml->{$b}{last_modified} cmp $xml->{$a}{last_modified}} keys %$xml) {
	my %entry = %{ $xml->{$_} ***REMOVED***
	$result->{$_} = \%entry;
	$num--;
	last unless $num;
  ***REMOVED***
    return $result;
}
sub module_exist ($) {
    my ($module) = @_;
    $module =~ s/::/\//g;
    foreach (@INC) {
	return 1 if (-e $_."/".$module.".pm"***REMOVED***
  ***REMOVED***
    return 0;
}

sub debug_scripts ($) {
    my ($scripts) = @_;
    my %result;
    foreach (@{$scripts}) {
	my $xml = get_scripts(***REMOVED***
	if (defined $xml->{$_.".pl"}{modules}) {
	    my $modules = $xml->{$_.".pl"}{modules***REMOVED***
	    foreach my $mod (split(/ /, $modules)) {
                my $opt = ($mod =~ /\((.*)\)/)? 1 : 0;
                $mod = $1 if $1;
                $result{$_}{$mod}{optional} = $opt;
                $result{$_}{$mod}{installed} = module_exist($mod***REMOVED***
	  ***REMOVED***
	}
  ***REMOVED***
    return(\%result***REMOVED***
}

sub install_scripts ($$) {
    my ($scripts, $xml) = @_;
    my %success;
    #$success{-foo} = 1;
    my $dir = Irssi::get_irssi_dir()."/scripts/";
    foreach (@{$scripts}) {
	if (get_local_version($_) && (-e $dir.$_.".pl")) {
	    $success{$_}{installed} = -2;
	} else {
	    $success{$_} = download_script($_, $xml***REMOVED***
	}
  ***REMOVED***
    return \%success;
}

sub update_scripts ($$) {
    my ($list, $database) = @_;
    $list = loaded_scripts() if ($list->[0] eq "all" || scalar(@$list) == 0***REMOVED***
    my %status;
    #$status{-foo} = 1;
    foreach (@{$list}) {
	my $local = get_local_version($_***REMOVED***
	my $remote = get_remote_version($_, $database***REMOVED***
	next if $local eq '' || $remote eq '';
	if (compare_versions($local, $remote) eq "older") {
	    $status{$_} = download_script($_, $database***REMOVED***
	} else {
	    $status{$_}{installed} = -2;
	}
	$status{$_}{remote} = $remote;
	$status{$_}{local} = $local;
  ***REMOVED***
    return \%status;
}

sub search_scripts ($$) {
    my ($query, $database) = @_;
    my %result;
    #$result{-foo} = " ";
    foreach (sort keys %{$database}) {
	my %entry = %{$database->{$_}***REMOVED***
	my $string = $_." ";
	$string .= $entry{description} if defined $entry{description***REMOVED***
	if ($string =~ /$query/i) {
	    my $name = $_;
	    $name =~ s/\.pl$//;
	    if (defined $entry{description}) {
		$result{$name}{desc} = $entry{description***REMOVED***
	  ***REMOVED*** else {
		$result{$name}{desc} = "";
	  ***REMOVED***
	    if (defined $entry{authors}) {
		$result{$name}{authors} = $entry{authors***REMOVED***
	  ***REMOVED*** else {
		$result{$name}{authors} = "";
	  ***REMOVED***
	    if (get_local_version($name)) {
		$result{$name}{installed} = 1;
	  ***REMOVED*** else {
		$result{$name}{installed} = 0;
	  ***REMOVED***
	}
  ***REMOVED***
    return \%result;
}

sub pipe_input {
    my ($rh, $pipetag) = @{$_[0]***REMOVED***
    my @lines = <$rh>;
    close($rh***REMOVED***
    Irssi::input_remove($$pipetag***REMOVED***
    $forked = 0;
    my $text = join("", @lines***REMOVED***
    unless ($text) {
	print CLIENTCRAP "%R<<%n Something weird happend";
	return(***REMOVED***
  ***REMOVED***
    no strict "vars";
    my $incoming = eval("$text"***REMOVED***
    if ($incoming->{db} && $incoming->{timestamp}) {
    	$remote_db{db} = $incoming->{db***REMOVED***
    	$remote_db{timestamp} = $incoming->{timestamp***REMOVED***
  ***REMOVED***
    unless (defined $incoming->{data}) {
	print CLIENTCRAP "%R<<%n Something weird happend";
	return;
  ***REMOVED***
    my %result = %{ $incoming->{data} ***REMOVED***
    @complist = (***REMOVED***
    if (defined $result{new}) {
	print_new($result{new}***REMOVED***
	push @complist, $_ foreach keys %{ $result{new} ***REMOVED***
  ***REMOVED***
    if (defined $result{check}) {
	print_check(%{$result{check}}***REMOVED***
	push @complist, $_ foreach keys %{ $result{check} ***REMOVED***
  ***REMOVED***
    if (defined $result{update}) {
	print_update(%{ $result{update} }***REMOVED***
	push @complist, $_ foreach keys %{ $result{update} ***REMOVED***
  ***REMOVED***
    if (defined $result{search}) {
	foreach (keys %{$result{search}}) {
	    print_search($_, %{$result{search}{$_}}***REMOVED***
	    push @complist, keys(%{$result{search}{$_}}***REMOVED***
	}
  ***REMOVED***
    if (defined $result{install}) {
	print_install(%{ $result{install} }***REMOVED***
	push @complist, $_ foreach keys %{ $result{install} ***REMOVED***
  ***REMOVED***
    if (defined $result{debug}) {
	print_debug(%{ $result{debug} }***REMOVED***
  ***REMOVED***
    if (defined $result{rating}) {
	print_ratings(%{ $result{rating} }***REMOVED***
	push @complist, $_ foreach keys %{ $result{rating} ***REMOVED***
  ***REMOVED***
    if (defined $result{rate}) {
	print_rate(%{ $result{rate} }***REMOVED***
  ***REMOVED***
    if (defined $result{info}) {
	print_info(%{ $result{info} }***REMOVED***
  ***REMOVED***
    if (defined $result{echo}) {
	Irssi::print "ECHO";
  ***REMOVED***
    if ($result{unknown}) {
        print_unknown($result{unknown}***REMOVED***
  ***REMOVED***

}

sub print_unknown ($) {
    my ($data) = @_;
    foreach my $cmd (keys %$data) {
	print CLIENTCRAP "%R<<%n No script provides '/$cmd'" unless $data->{$cmd***REMOVED***
	foreach (keys %{ $data->{$cmd} }) {
	    my $text .= "The command '/".$cmd."' is provided by the script '".$data->{$cmd}{$_}{name}."'.\n";
	    $text .= "This script is currently not installed on your system.\n";
	    $text .= "If you want to install the script, enter\n";
	    my ($name) = /(.*?)\.pl$/;
	    $text .= "  %U/script install ".$name."%U ";
	    my $output = draw_box("ScriptAssist", $text, "'".$_."' missing", 1***REMOVED***
	    print CLIENTCRAP $output;
	}
  ***REMOVED***
}

sub check_autorun ($) {
    my ($script) = @_;
    my $dir = Irssi::get_irssi_dir()."/scripts/";
    if (-e $dir."/autorun/".$script.".pl") {
	if (readlink($dir."/autorun/".$script.".pl") eq "../".$script.".pl") {
	    return 1;
	}
  ***REMOVED***
    return 0;
}

sub array2table {
    my (@array) = @_;
    my @width;
    foreach my $line (@array) {
        for (0..scalar(@$line)-1) {
            my $l = $line->[$_];
            $l =~ s/%[^%]//g;
            $l =~ s/%%/%/g;
            $width[$_] = length($l) if $width[$_]<length($l***REMOVED***
      ***REMOVED***
  ***REMOVED***   
    my $text;
    foreach my $line (@array) {
        for (0..scalar(@$line)-1) {
            my $l = $line->[$_];
            $text .= $line->[$_];
            $l =~ s/%[^%]//g;
            $l =~ s/%%/%/g;
            $text .= " "x($width[$_]-length($l)+1) unless ($_ == scalar(@$line)-1***REMOVED***
      ***REMOVED***
        $text .= "\n";
  ***REMOVED***
    return $text;
}


sub print_info (%) {
    my (%data) = @_;
    my $line;
    foreach my $script (sort keys(%data)) {
	my ($local, $autorun***REMOVED***
	if (get_local_version($script)) {
	    $line .= "%go%n ";
	    $local = get_local_version($script***REMOVED***
	} else {
	    $line .= "%ro%n ";
	    $local = undef;
	}
	if (defined $local || check_autorun($script)) {
	    $autorun = "no";
	    $autorun = "yes" if check_autorun($script***REMOVED***
	} else {
	    $autorun = undef;
	}
	$line .= "%9".$script."%9\n";
	$line .= "  Version    : ".$data{$script}{version}."\n";
	$line .= "  Source     : ".$data{$script}{source}."\n";
	$line .= "  Installed  : ".$local."\n" if defined $local;
	$line .= "  Autorun    : ".$autorun."\n" if defined $autorun;
	$line .= "  Authors    : ".$data{$script}{authors***REMOVED***
	$line .= " %Go-m signed%n" if $data{$script}{signature_available***REMOVED***
	$line .= "\n";
	$line .= "  Contact    : ".$data{$script}{contact}."\n";
	$line .= "  Description: ".$data{$script}{description}."\n";
	$line .= "\n" if $data{$script}{modules***REMOVED***
	$line .= "  Needed Perl modules:\n" if $data{$script}{modules***REMOVED***

        foreach (sort keys %{$data{$script}{modules}}) {
            if ( $data{$script}{modules}{$_}{installed} == 1 ) {
                $line .= "  %g->%n ".$_." (found)";
          ***REMOVED*** else {
                $line .= "  %r->%n ".$_." (not found)";
          ***REMOVED***
	    $line .= " <optional>" if $data{$script}{modules}{$_}{optional***REMOVED***
            $line .= "\n";
      ***REMOVED***
	#$line .= "  Needed Irssi scripts:\n";
	$line .= "  Needed Irssi Scripts:\n" if $data{$script}{depends***REMOVED***
	foreach (sort keys %{$data{$script}{depends}}) {
	    if ( $data{$script}{depends}{$_}{installed} == 1 ) {
		$line .= "  %g->%n ".$_." (loaded)";
	  ***REMOVED*** else {
		$line .= "  %r->%n ".$_." (not loaded)";
	  ***REMOVED***
	    #$line .= " <optional>" if $data{$script}{depends}{$_}{optional***REMOVED***
	    $line .= "\n";
	}
  ***REMOVED***
    print CLIENTCRAP draw_box('ScriptAssist', $line, 'info', 1) ;
}

sub print_rate (%) {
    my (%data) = @_;
    my $line;
    foreach my $script (sort keys(%data)) {
	if ($data{$script}) {
            $line .= "%go%n %9".$script."%9 has been rated";
      ***REMOVED*** else {
            $line .= "%ro%n %9".$script."%9 : Already rated this script";
      ***REMOVED***
  ***REMOVED***
    print CLIENTCRAP draw_box('ScriptAssist', $line, 'rating', 1) ;
}

sub print_ratings (%) {
    my (%data) = @_;
    my @table;
    foreach my $script (sort {$data{$b}{rating}<=>$data{$a}{rating}} keys(%data)) {
	my @line;
	if (get_local_version($script)) {
	    push @line, "%go%n";
	} else {
	    push @line, "%yo%n";
	}
        push @line, "%9".$script."%9";
	push @line, $data{$script}{rating***REMOVED***
	push @line, "[".$data{$script}{votes}." votes]";
	push @table, \@line;
  ***REMOVED***
    print CLIENTCRAP draw_box('ScriptAssist', array2table(@table), 'ratings', 1) ;
}

sub print_new ($) {
    my ($list) = @_;
    my @table;
    foreach (sort {$list->{$b}{last_modified} cmp $list->{$a}{last_modified}} keys %$list) {
	my @line;
	my ($name) = /^(.*?)\.pl$/;
        if (get_local_version($name)) {
            push @line, "%go%n";
      ***REMOVED*** else {
            push @line, "%yo%n";
      ***REMOVED***
	push @line, "%9".$name."%9";
	push @line, $list->{$_}{last_modified***REMOVED***
	push @table, \@line;
  ***REMOVED***
    print CLIENTCRAP draw_box('ScriptAssist', array2table(@table), 'new scripts', 1) ;
}

sub print_debug (%) {
    my (%data) = @_;
    my $line;
    foreach my $script (sort keys %data) {
	$line .= "%ro%n %9".$script."%9 failed to load\n";
	$line .= "  Make sure you have the following perl modules installed:\n";
	foreach (sort keys %{$data{$script}}) {
	    if ( $data{$script}{$_}{installed} == 1 ) {
		$line .= "  %g->%n ".$_." (found)";
	  ***REMOVED*** else {
		$line .= "  %r->%n ".$_." (not found)\n";
		$line .= "     [This module is optional]\n" if $data{$script}{$_}{optional***REMOVED***
		$line .= "     [Try /scriptassist cpan ".$_."]";
	  ***REMOVED***
	    $line .= "\n";
	}
	print CLIENTCRAP draw_box('ScriptAssist', $line, 'debug', 1) ;
  ***REMOVED***
}

sub load_script ($) {
    my ($script) = @_;
    Irssi::command('script load '.$script***REMOVED***
}

sub print_install (%) {
    my (%data) = @_;
    my $text;
    my ($crashed, @installed***REMOVED***
    foreach my $script (sort keys %data) {
	my $line;
	if ($data{$script}{installed} == 1) {
	    my $hacked;
	    if ($have_gpg && Irssi::settings_get_bool('scriptassist_use_gpg')) {
		if ($data{$script}{signed} >= 0) {
		    load_script($script) unless (lc($script) eq lc($IRSSI{name})***REMOVED***
		} else {
		    $hacked = 1;
		}
	  ***REMOVED*** else {
		load_script($script) unless (lc($script) eq lc($IRSSI{name})***REMOVED***
	  ***REMOVED***
    	    if (get_local_version($script) && not lc($script) eq lc($IRSSI{name})) {
		$line .= "%go%n %9".$script."%9 installed\n";
		push @installed, $script;
	  ***REMOVED*** elsif (lc($script) eq lc($IRSSI{name})) {
		$line .= "%yo%n %9".$script."%9 installed, please reload manually\n";
	  ***REMOVED*** else {
    		$line .= "%Ro%n %9".$script."%9 fetched, but unable to load\n";
		$crashed .= $script." " unless $hacked;
	  ***REMOVED***
	    if ($have_gpg && Irssi::settings_get_bool('scriptassist_use_gpg')) {
		foreach (split /\n/, check_sig($data{$script})) {
		    $line .= "  ".$_."\n";
		}
	  ***REMOVED***
	} elsif ($data{$script}{installed} == -2) {
	    $line .= "%ro%n %9".$script."%9 already loaded, please try \"update\"\n";
	} elsif ($data{$script}{installed} <= 0) {
	    $line .= "%ro%n %9".$script."%9 not installed\n";
    	    foreach (split /\n/, check_sig($data{$script})) {
		$line .= "  ".$_."\n";
	  ***REMOVED***
	} else {
	    $line .= "%Ro%n %9".$script."%9 not found on server\n";
	}
	$text .= $line;
  ***REMOVED***
    # Inspect crashed scripts
    bg_do("debug ".$crashed) if $crashed;
    print CLIENTCRAP draw_box('ScriptAssist', $text, 'install', 1***REMOVED***
    list_sbitems(\@installed***REMOVED***
}

sub list_sbitems ($) {
    my ($scripts) = @_;
    my $text;
    foreach (@$scripts) {
	no strict 'refs';
	next unless  %{ "Irssi::Script::${_}::" ***REMOVED***
	next unless  %{ "Irssi::Script::${_}::IRSSI" ***REMOVED***
	my %header = %{ "Irssi::Script::${_}::IRSSI" ***REMOVED***
	next unless $header{sbitems***REMOVED***
	$text .= '%9"'.$_.'"%9 provides the following statusbar item(s):'."\n";
	$text .= '  ->'.$_."\n" foreach (split / /, $header{sbitems}***REMOVED***
  ***REMOVED***
    return unless $text;
    $text .= "\n";
    $text .= "Enter '/statusbar window add <item>' to add an item.";
    print CLIENTCRAP draw_box('ScriptAssist', $text, 'sbitems', 1***REMOVED***
}

sub check_sig ($) {
    my ($sig) = @_;
    my $line;
    my %trust = ( -1 => 'undefined',
                   0 => 'never',
		   1 => 'marginal',
		   2 => 'fully',
		   3 => 'ultimate'
		 ***REMOVED***
    if ($sig->{signed} == 1) {
	$line .= "Signature found from ".$sig->{sig}{user}."\n";
	$line .= "Timestamp  : ".$sig->{sig}{date}."\n";
	$line .= "Fingerprint: ".$sig->{sig}{fingerprint}."\n";
	$line .= "KeyID      : ".$sig->{sig}{keyid}."\n";
	$line .= "Trust      : ".$trust{$sig->{sig}{trust}}."\n";
  ***REMOVED*** elsif ($sig->{signed} == -1) {
	$line .= "%1Warning, unable to verify signature%n\n";
  ***REMOVED*** elsif ($sig->{signed} == 0) {
	$line .= "%1No signature found%n\n" unless Irssi::settings_get_bool('scriptassist_install_unsigned_scripts'***REMOVED***
  ***REMOVED***
    return $line;
}

sub print_search ($%) {
    my ($query, %data) = @_;
    my $text;
    foreach (sort keys %data) {
	my $line;
	$line .= "%go%n" if $data{$_}{installed***REMOVED***
	$line .= "%yo%n" if not $data{$_}{installed***REMOVED***
	$line .= " %9".$_."%9 ";
	$line .= $data{$_}{desc***REMOVED***
	$line =~ s/($query)/%U$1%U/gi;
	$line .= ' ('.$data{$_}{authors}.')';
	$text .= $line." \n";
  ***REMOVED***
    print CLIENTCRAP draw_box('ScriptAssist', $text, 'search: '.$query, 1) ;
}

sub print_update (%) { 
    my (%data) = @_;
    my $text;
    my @table;
    my $verbose = Irssi::settings_get_bool('scriptassist_update_verbose'***REMOVED***
    foreach (sort keys %data) {
	my $signed = 0;
	if ($data{$_}{installed} == 1) {
	    my $local = $data{$_}{local***REMOVED***
	    my $remote = $data{$_}{remote***REMOVED***
	    push @table, ['%yo%n', '%9'.$_.'%9', 'upgraded ('.$local.'->'.$remote.')'];
	    foreach (split /\n/, check_sig($data{$_})) {
		push @table, ['', '', $_];
	  ***REMOVED***
	    if (lc($_) eq lc($IRSSI{name})) {
		push @table, ['', '', "%R%9Please reload manually%9%n"];
	  ***REMOVED*** else {
		load_script($_***REMOVED***
	  ***REMOVED***
	} elsif ($data{$_}{installed} == 0 || $data{$_}{installed} == -1) {
	    push @table, ['%yo%n', '%9'.$_.'%9', 'not upgraded'];
            foreach (split /\n/, check_sig($data{$_})) {
		push @table, ['', '', $_];
          ***REMOVED*** 
	} elsif ($data{$_}{installed} == -2 && $verbose) {
	    my $local = $data{$_}{local***REMOVED***
	    push @table, ['%go%n', '%9'.$_.'%9', 'already at the latest version ('.$local.')'];
    	}
  ***REMOVED***
    $text = array2table(@table***REMOVED***
    print CLIENTCRAP draw_box('ScriptAssist', $text, 'update', 1) ;
}

sub contact_author ($) {
    my ($script) = @_;
    no strict 'refs';
    return unless  %{ "Irssi::Script::${script}::" ***REMOVED***
    my %header = %{ "Irssi::Script::${script}::IRSSI" ***REMOVED***
    if (defined $header{contact}) {
	my @ads = split(/ |,/, $header{contact}***REMOVED***
	my $address = $ads[0];
	$address .= '?subject='.$script;
	$address .= '_'.get_local_version($script) if defined get_local_version($script***REMOVED***
	call_openurl($address***REMOVED***
  ***REMOVED***
}

sub get_scripts {
    my $ua = LWP::UserAgent->new(env_proxy=>1, keep_alive=>1, timeout=>30***REMOVED***
    $ua->agent('ScriptAssist/'.$VERSION***REMOVED***
    $ua->env_proxy(***REMOVED***
    my @mirrors = split(/ /, Irssi::settings_get_str('scriptassist_script_sources')***REMOVED***
    my %sites_db;
    my $fetched = 0;
    my @sources;
    foreach my $site (@mirrors) {
	my $request = HTTP::Request->new('GET', $site***REMOVED***
	if ($remote_db{timestamp}) {
	    $request->if_modified_since($remote_db{timestamp}***REMOVED***
	}
	my $response = $ua->request($request***REMOVED***
	next unless $response->is_success;
	$fetched = 1;
	my $data = $response->content(***REMOVED***
	my ($src, $type***REMOVED***
	if ($site =~ /(.*\/).+\.(.+)/) {
	    $src = $1;
	    $type = $2;
	}
	push @sources, $src;
	#my @header = ('name', 'contact', 'authors', 'description', 'version', 'modules', 'last_modified'***REMOVED***
	if ($type eq 'dmp') {
	    no strict 'vars';
	    my $new_db = eval "$data";
	    foreach (keys %$new_db) {
		if (defined $sites_db{script}{$_}) {
		    my $old = $sites_db{$_}{version***REMOVED***
		    my $new = $new_db->{$_}{version***REMOVED***
		    next if (compare_versions($old, $new) eq 'newer'***REMOVED***
		}
		#foreach my $key (@header) {
		foreach my $key (keys %{ $new_db->{$_} }) {
		    next unless defined $new_db->{$_}{$key***REMOVED***
		    $sites_db{$_}{$key} = $new_db->{$_}{$key***REMOVED***
		}
		$sites_db{$_}{source} = $src;
	  ***REMOVED***
	} else {
	    ## FIXME Panic?!
	}
	
  ***REMOVED***
    if ($fetched) {
	# Clean database
	foreach (keys %{$remote_db{db}}) {
	    foreach my $site (@sources) {
		if ($remote_db{db}{$_}{source} eq $site) {
		    delete $remote_db{db}{$_***REMOVED***
		    last;
		}
	  ***REMOVED***
	}
	$remote_db{db}{$_} = $sites_db{$_} foreach (keys %sites_db***REMOVED***
	$remote_db{timestamp} = time(***REMOVED***
  ***REMOVED***
    return $remote_db{db***REMOVED***
}

sub get_remote_version ($$) {
    my ($script, $database) = @_;
    return $database->{$script.".pl"}{version***REMOVED***
}

sub get_local_version ($) {
    my ($script) = @_;
    no strict 'refs';
    return unless  %{ "Irssi::Script::${script}::" ***REMOVED***
    my $version = ${ "Irssi::Script::${script}::VERSION" ***REMOVED***
    return $version;
}

sub compare_versions ($$) {
    my ($ver1, $ver2) = @_;
    my @ver1 = split /\./, $ver1;
    my @ver2 = split /\./, $ver2;
    #if (scalar(@ver2) != scalar(@ver1)) {
    #    return 0;
    #}       
    my $cmp = 0;
    ### Special thanks to Clemens Heidinger
    $cmp ||= $ver1[$_] <=> $ver2[$_] || $ver1[$_] cmp $ver2[$_] for 0..scalar(@ver2***REMOVED***
    return 'newer' if $cmp == 1;
    return 'older' if $cmp == -1;
    return 'equal';
}

sub loaded_scripts {
    no strict 'refs';
    my @modules;
    foreach (sort grep(s/::$//, keys %Irssi::Script::)) {
        #my $name    = ${ "Irssi::Script::${_}::IRSSI" }{name***REMOVED***
        #my $version = ${ "Irssi::Script::${_}::VERSION" ***REMOVED***
	push @modules, $_;# if $name && $version;
  ***REMOVED***
    return \@modules;

}

sub check_scripts {
    my ($data) = @_;
    my %versions;
    #$versions{-foo} = 1;
    foreach (@{loaded_scripts()}) {
        my $remote = get_remote_version($_, $data***REMOVED***
        my $local =  get_local_version($_***REMOVED***
	my $state;
	if ($local && $remote) {
	    $state = compare_versions($local, $remote***REMOVED***
	} elsif ($local) {
	    $state = 'noversion';
	    $remote = '/';
	} else {
	    $state = 'noheader';
	    $local = '/';
	    $remote = '/';
	}
	if ($state) {
	    $versions{$_}{state} = $state;
	    $versions{$_}{remote} = $remote;
	    $versions{$_}{local} = $local;
	}
  ***REMOVED***
    return \%versions;
}

sub download_script ($$) {
    my ($script, $xml) = @_;
    my %result;
    my $site = $xml->{$script.".pl"}{source***REMOVED***
    $result{installed} = 0;
    $result{signed} = 0;
    my $dir = Irssi::get_irssi_dir(***REMOVED***
    my $ua = LWP::UserAgent->new(env_proxy => 1,keep_alive => 1,timeout => 30***REMOVED***
    $ua->agent('ScriptAssist/'.$VERSION***REMOVED***
    my $request = HTTP::Request->new('GET', $site.'/scripts/'.$script.'.pl'***REMOVED***
    my $response = $ua->request($request***REMOVED***
    if ($response->is_success()) {
	my $file = $response->content(***REMOVED***
	mkdir $dir.'/scripts/' unless (-e $dir.'/scripts/'***REMOVED***
	local *F;
	open(F, '>'.$dir.'/scripts/'.$script.'.pl.new'***REMOVED***
	print F $file;
	close(F***REMOVED***
	if ($have_gpg && Irssi::settings_get_bool('scriptassist_use_gpg')) {
	    my $ua2 = LWP::UserAgent->new(env_proxy => 1,keep_alive => 1,timeout => 30***REMOVED***
	    $ua->agent('ScriptAssist/'.$VERSION***REMOVED***
	    my $request2 = HTTP::Request->new('GET', $site.'/signatures/'.$script.'.pl.asc'***REMOVED***
	    my $response2 = $ua->request($request2***REMOVED***
	    if ($response2->is_success()) {
		local *S;
		my $sig_dir = $dir.'/scripts/signatures/';
		mkdir $sig_dir unless (-e $sig_dir***REMOVED***
		open(S, '>'.$sig_dir.$script.'.pl.asc'***REMOVED***
		my $file2 = $response2->content(***REMOVED***
		print S $file2;
		close(S***REMOVED***
		my $sig;
		foreach (1..2) {
		    # FIXME gpg needs two rounds to load the key
		    my $gpg = new GnuPG(***REMOVED***
		    eval {
			$sig = $gpg->verify( file => $dir.'/scripts/'.$script.'.pl.new', signature => $sig_dir.$script.'.pl.asc' ***REMOVED***
		  ***REMOVED***;
		}
		if (defined $sig->{user}) {
		    $result{installed} = 1;
		    $result{signed} = 1;
		    $result{sig}{$_} = $sig->{$_} foreach (keys %{$sig}***REMOVED***
		} else {
		    # Signature broken?
		    $result{installed} = 0;
		    $result{signed} = -1;
		}
	  ***REMOVED*** else {
		$result{signed} = 0;
		$result{installed} = -1;
		$result{installed} = 1 if Irssi::settings_get_bool('scriptassist_install_unsigned_scripts'***REMOVED***
	  ***REMOVED***
	} else {
	    $result{signed} = 0;
	    $result{installed} = -1;
	    $result{installed} = 1 if Irssi::settings_get_bool('scriptassist_install_unsigned_scripts'***REMOVED***
	}
  ***REMOVED***
    if ($result{installed}) {
	my $old_dir = "$dir/scripts/old/";
	mkdir $old_dir unless (-e $old_dir***REMOVED***
	rename "$dir/scripts/$script.pl", "$old_dir/$script.pl.old" if -e "$dir/scripts/$script.pl";
	rename "$dir/scripts/$script.pl.new", "$dir/scripts/$script.pl";
  ***REMOVED***
    return \%result;
}

sub print_check (%) {
    my (%data) = @_;
    my $text;
    my @table;
    foreach (sort keys %data) {
	my $state = $data{$_}{state***REMOVED***
	my $remote = $data{$_}{remote***REMOVED***
	my $local = $data{$_}{local***REMOVED***
	if (Irssi::settings_get_bool('scriptassist_check_verbose')) {
	    push @table, ['%go%n', '%9'.$_.'%9', 'Up to date. ('.$local.')'] if $state eq 'equal';
	}
	push @table, ['%mo%n', '%9'.$_.'%9', "No version information available on network."] if $state eq "noversion";
	push @table, ['%mo%n', '%9'.$_.'%9', 'No header in script.'] if $state eq "noheader";
	push @table, ['%bo%n', '%9'.$_.'%9', "Your version is newer (".$local."->".$remote.")"] if $state eq "newer";
	push @table, ['%ro%n', '%9'.$_.'%9', "A new version is available (".$local."->".$remote.")"] if $state eq "older";;
  ***REMOVED***
    $text = array2table(@table***REMOVED***
    print CLIENTCRAP draw_box('ScriptAssist', $text, 'check', 1) ;
}

sub toggle_autorun ($) {
    my ($script) = @_;
    my $dir = Irssi::get_irssi_dir()."/scripts/";
    mkdir $dir."autorun/" unless (-e $dir."autorun/"***REMOVED***
    return unless (-e $dir.$script.".pl"***REMOVED***
    if (check_autorun($script)) {
	if (readlink($dir."/autorun/".$script.".pl") eq "../".$script.".pl") {
	    if (unlink($dir."/autorun/".$script.".pl")) {
		print CLIENTCRAP "%R>>%n Autorun of ".$script." disabled";
	  ***REMOVED*** else {
		print CLIENTCRAP "%R>>%n Unable to delete link";
	  ***REMOVED***
	} else {
	    print CLIENTCRAP "%R>>%n ".$dir."/autorun/".$script.".pl is not a correct link";
	}
  ***REMOVED*** else {
	symlink("../".$script.".pl", $dir."/autorun/".$script.".pl"***REMOVED***
    	print CLIENTCRAP "%R>>%n Autorun of ".$script." enabled";
  ***REMOVED***
}

sub sig_script_error ($$) {
    my ($script, $msg) = @_;
    return unless Irssi::settings_get_bool('scriptassist_catch_script_errors'***REMOVED***
    if ($msg =~ /Can't locate (.*?)\.pm in \@INC \(\@INC contains:(.*?) at/) {
        my $module = $1;
        $module =~ s/\//::/g;
	missing_module($module***REMOVED***
  ***REMOVED***
}

sub missing_module ($$) {
    my ($module) = @_;
    my $text;
    $text .= "The perl module %9".$module."%9 is missing on your system.\n";
    $text .= "Please ask your administrator about it.\n";
    $text .= "You can also check CPAN via '/scriptassist cpan ".$module."'.\n";
    print CLIENTCRAP &draw_box('ScriptAssist', $text, $module, 1***REMOVED***
}

sub cmd_scripassist ($$$) {
    my ($arg, $server, $witem) = @_;
    my @args = split(/ /, $arg***REMOVED***
    if ($args[0] eq 'help' || $args[0] eq '-h') {
	show_help(***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'check') {
	bg_do("check"***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'update') {
	shift @args;
	bg_do("update ".join(' ', @args)***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'search' && defined $args[1]) {
	shift @args;
	bg_do("search ".join(" ", @args)***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'install' && defined $args[1]) {
	shift @args;
	bg_do("install ".join(' ', @args)***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'contact' && defined $args[1]) {
	contact_author($args[1]***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'ratings' && defined $args[1]) {
	shift @args;
	bg_do("ratings ".join(' ', @args)***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'rate' && defined $args[1] && defined $args[2]) {
	shift @args;
	bg_do("rate ".join(' ', @args)) if ($args[2] >= 0 && $args[2] < 6***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'info' && defined $args[1]) {
	shift @args;
	bg_do("info ".join(' ', @args)***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'echo') {
	bg_do("echo"***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'top') {
	my $number = defined $args[1] ? $args[1] : 10;
	bg_do("top ".$number***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'cpan' && defined $args[1]) {
	call_openurl('http://search.cpan.org/search?mode=module&query='.$args[1]***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'autorun' && defined $args[1]) {
	toggle_autorun($args[1]***REMOVED***
  ***REMOVED*** elsif ($args[0] eq 'new') {
	my $number = defined $args[1] ? $args[1] : 5;
	bg_do("new ".$number***REMOVED***
  ***REMOVED***
}

sub sig_command_script_load ($$$) {
    my ($script, $server, $witem) = @_;
    no strict;
    $script = $2 if $script =~ /(.*\/)?(.*?)\.pl$/;
    if ( %{ "Irssi::Script::${script}::" }) {
	if (defined &{ "Irssi::Script::${script}::pre_unload" }) {
	    print CLIENTCRAP "%R>>%n Triggering pre_unload function of $script...";
	    &{ "Irssi::Script::${script}::pre_unload" }(***REMOVED***
	}
  ***REMOVED***
}

sub sig_default_command ($$) {
    my ($cmd, $server) = @_;
    return unless Irssi::settings_get_bool("scriptassist_check_unknown_commands"***REMOVED***
    bg_do('unknown '.$cmd***REMOVED***
}

sub sig_complete ($$$$$) {
    my ($list, $window, $word, $linestart, $want_space) = @_;
    return unless $linestart =~ /^.script(assist)? (install|rate|ratings|update|check|contact|info|autorun)/;
    my @newlist;
    my $str = $word;
    foreach (@complist) {
	if ($_ =~ /^(\Q$str\E.*)?$/) {
	    push @newlist, $_;
	}
  ***REMOVED***
    foreach (@{loaded_scripts()}) {
	push @newlist, $_ if /^(\Q$str\E.*)?$/;
  ***REMOVED***
    $want_space = 0;
    push @$list, $_ foreach @newlist;
    Irssi::signal_stop(***REMOVED***
}


Irssi::settings_add_str($IRSSI{name}, 'scriptassist_script_sources', 'http://scripts.irssi.org/scripts.dmp'***REMOVED***
Irssi::settings_add_bool($IRSSI{name}, 'scriptassist_cache_sources', 1***REMOVED***
Irssi::settings_add_bool($IRSSI{name}, 'scriptassist_update_verbose', 1***REMOVED***
Irssi::settings_add_bool($IRSSI{name}, 'scriptassist_check_verbose', 1***REMOVED***
Irssi::settings_add_bool($IRSSI{name}, 'scriptassist_catch_script_errors', 1***REMOVED***

Irssi::settings_add_bool($IRSSI{name}, 'scriptassist_install_unsigned_scripts', 1***REMOVED***
Irssi::settings_add_bool($IRSSI{name}, 'scriptassist_use_gpg', 1***REMOVED***
Irssi::settings_add_bool($IRSSI{name}, 'scriptassist_integrate', 1***REMOVED***
Irssi::settings_add_bool($IRSSI{name}, 'scriptassist_check_unknown_commands', 1***REMOVED***

Irssi::signal_add_first("default command", \&sig_default_command***REMOVED***
Irssi::signal_add_first('complete word', \&sig_complete***REMOVED***
Irssi::signal_add_first('command script load', \&sig_command_script_load***REMOVED***
Irssi::signal_add_first('command script unload', \&sig_command_script_load***REMOVED***

if (defined &Irssi::signal_register) {
    Irssi::signal_register({ 'script error' => [ 'Irssi::Script', 'string' ] }***REMOVED***
    Irssi::signal_add_last('script error', \&sig_script_error***REMOVED***
}

Irssi::command_bind('scriptassist', \&cmd_scripassist***REMOVED***

Irssi::theme_register(['box_header', '%R,--[%n$*%R]%n',
'box_inside', '%R|%n $*',
'box_footer', '%R`--<%n$*%R>->%n',
]***REMOVED***

foreach my $cmd ( ( 'check', 'install', 'update', 'contact', 'search', '-h', 'help', 'ratings', 'rate', 'info', 'echo', 'top', 'cpan', 'autorun', 'new') ) {
    Irssi::command_bind('scriptassist '.$cmd => sub {
			cmd_scripassist("$cmd ".$_[0], $_[1], $_[2]***REMOVED*** }***REMOVED***
    if (Irssi::settings_get_bool('scriptassist_integrate')) {
	Irssi::command_bind('script '.$cmd => sub {
    			    cmd_scripassist("$cmd ".$_[0], $_[1], $_[2]***REMOVED*** }***REMOVED***
  ***REMOVED***
}

print CLIENTCRAP '%B>>%n '.$IRSSI{name}.' '.$VERSION.' loaded: /scriptassist help for help';
