package IO::Screen;

use strict;
use warnings;
use IO::Pty;
use IO::Socket::UNIX;
use IO::Select;
use Carp;
our @ISA = qw(IO::Pty);

# dynamically create all the subs vars at compile time. its a pain to reference things in a blessed file handle.
# This is copied from some old code of mine.
BEGIN {
	for my $var (qw/args parent child/) {
		no strict 'refs';
		*$var = sub {
			my ($pty, $args) = @_;
			my $ref = \${*$pty}{"io_screen_$var"};
			$$ref = $args if defined $args;
			return $$ref;
		}
	}
}

# creates the pty and sets it to raw
sub new {
	my ($class, %args) = @_;
	my $pty = $class->SUPER::new();
	$pty->set_raw;
	$pty->args(\%args);
	return $pty;
}

# forks and keeps the parent as a socket listener and hands control back to the calling script for the child
sub create {
	my $pty = shift;
	$pty->parent($$);
	$pty->child(fork);
	if ($pty->child > 0) {
# PARENT
	close(STDIN);
	close(STDOUT);
	close(STDERR);
		my $socket = IO::Socket::UNIX->new(
				Type => SOCK_STREAM,
				Local => $pty->args->{File},
				Listen => 1,
				) or croak "failed to create socket";

		my $sel = IO::Select->new();
		while(my $client = $socket->accept) {
			$sel->add($pty);
			$sel->add($client);
			my $input;
			my @ready;
			while(@ready = $sel->can_read) {
				for my $fh (@ready) {
					if($fh == $pty) {
						$pty->sysread($input, 128, 0);
						$client->syswrite ($input, length($input));
					} else {
						$client->sysread($input, 128, 0);
						$pty->syswrite($input, length($input));
					}
				}
				undef $input;
			}
		}
		exit;
	} elsif($pty->child == 0) {
# CHILD
		my $pts = $pty->slave;
# todo close all but pts and open these better (sysopen)
		close($pty);
	my $pid = $$;
	logthis("close",`ls -la /proc/$pid/fd/*`);
	close(STDIN);
	close(STDOUT);
	close(STDERR);
	logthis(`ls -la /proc/$pid/fd/*`);
		open(STDIN, '<&='.fileno($pts));
		open(STDOUT, '>&='.fileno($pts));
		open(STDERR, '>&='.fileno($pts));
	logthis(`ls -la /proc/$pid/fd/*`);
	} else {
		croak "cannot fork a child process";
	}
}

sub logthis {
	my @msg = @_;
	open LOG, '>>', 'logfile';
	for (@msg) {
		chomp;
		print LOG "$_\n";
	}
	close LOG;
}

1;
