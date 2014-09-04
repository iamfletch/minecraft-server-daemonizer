#!/usr/bin/perl

use strict;
use warnings;

close STDOUT;

open STDOUT, '>', 'logfile';

print "test";

close STDOUT;
