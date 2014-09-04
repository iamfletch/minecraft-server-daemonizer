package IO::Screen::Terminal;

use strict;
use warnings;
use IO::Socket;
use IO::Select;
our @ISA = qw(IO::Pty);

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub attach {
	my $self = shift;
# PARENT
	my $socket = IO::Socket::UNIX->new(Type=>SOCK_STREAM, Peer=>"/opt/minecraft-server-daemonizer-perl/socket");
	my $sel = IO::Select->new();
	$sel->add($socket);
	$sel->add(\*STDIN);
	my $input;
	my @ready;
	while(@ready = $sel->can_read) {
		for my $fh (@ready) {
			if($fh == $socket) {
				$socket->sysread($input, 128, 0);
				syswrite (STDOUT, $input);
			} else {
				sysread(STDIN, $input, 128, 0);
				$socket->syswrite($input, length($input));
			}
		}
		undef $input;
	}
	exit;
# CHILD
# todo close all but pts and open these better (sysopen)
}

1;
