#!/usr/bin/perl

use warnings;
use strict;

my $socket_file = "/opt/minecraft-server-daemonizer-perl/socket";

if (fork) { 
	use IO::Screen;
	my $server = new IO::Screen(File=>$socket_file);
	$server->create;
	exec('/usr/bin/bc');
} else {
	sleep 5;
	use IO::Screen::Terminal;
	my $terminal = new IO::Screen::Terminal(File=>$socket_file);
	print "still here\n";
	$terminal->attach;
}
