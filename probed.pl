#!/usr/bin/env perl
#: ----------------------------------------------------------------------------
#: probed - a module tracker for linux                  
#: ----------------------------------------------------------------------------
#:                                      							
#: Copyright (c)  ricky thomson (8th may 2011)                  		
#: License - GNU GPLv3                              				
#:                                      			
#: What is this?                              			
#: `probed` is a tiny script for tracking used kernel modules over time.   
#:                                      			
#: This can be very useful if you choose to compile your kernel with      
#: `make localmodconfig`.                           	
#:                                      			
#: How to use? Boot a precompiled kernel and attach every hardware device
#: that will be used with the machine (usb, dvb, external discs, cdrom -- etc)
#: so that the required kernel modules are loaded. Once you've gathered enough
#: modules (don't forget filesystems), by manually loading, or running probed
#: as a cron job, you can then run the script with the "--load" flag prior to
#: compiling your kernel with `make localmodmconfig`. This will compile the 
#: kernel with modules that were collected. This is usually done to speed up 
#: compiling times.
#:
#: TIP; if you don't want to spend the day inserting and removing random 
#: devices, run probed as a cron (use the -s flag for silent output) and wait 
#: a few days after some normal usage.
#: ----------------------------------------------------------------------------
use strict;
use warnings;

## default argv settings
my ( $cron, $colour ) = (0, 1);

my $db  = 'probed-modules.db';

## these are blacklisted because they are not included in the main kernel tree
## they are usually built on the target machine as modules, and cannot be compiled
## into the kernel, so we ignore them.
my @blacklist = qw(nvidia vboxdrv vboxnetflt vboxnetadp lirc_dev lirc_i2c);

## display usage information
sub usage {
	print "Usage:\t$0 [-chs]\n\n";
	print "   -h, --help\t\tshow this help\n";
	print "   -c, --colour\t\ttoggle colourized output\n";
	print "   -s, --silent\t\tcron (silent output)\n\n";
	print "   -l, --load\t\tload stored modules\n\n";
}

sub loadModules() {
	if ($< != 0) { 
		print "Need to be root.\n"; exit 2; 
	} else {
		open  DBASE, "<$db" or die $!; my @loadmodules = <DBASE>; close DBASE;
		foreach (@loadmodules) {
			`modprobe $_`;
			print "Loading $_";
		}
		print "Total Modules: ". @loadmodules  ."\n";
		exit 0; 

	}
	
}

## accept usage flags / parse them
foreach ( @ARGV ) {

	if ( $_ =~ m/^-(.+)/) {
		our $switch = $1;
		if ( $switch =~ m/(^h$|^-help$)/ ) { usage(); exit 0; } 
		if ( $switch =~ m/(^c$|^-colour$)/ ) { if ( $colour == 1 ) { $colour = 0; } else { $colour = 1 }; } 
		if ( $switch =~ m/(^s$|^-silent$)/ ) { if ( $cron   == 1 ) { $cron   = 0; } else { $cron   = 1 }; } 
		if ( $switch =~ m/(^l$|^-load$)/ ) { loadModules(); } 
	} else {
		usage();
		exit 2;
	}

}

## output formatting, detect cron flag, colour etc.
sub msg ($$) {
	our ( $message, $err ) = @_;
	our $code;


	if ( ! $cron == 1 && $colour == 1) { 
		## determine colour to use
		if ( $err == 0 ) { $code = "\033[1;31m"; }
		if ( $err == 1 ) { $code = "\033[1;33m"; }
		if ( $err == 2 ) { $code = "\033[1;32m"; }

		print $code . "===>\033[0m " . $message . "\n";

	} elsif ( ! $cron == 1 ) {
		print "===> " . $message . "\n";        
	}
}

## ensure the database file exists
if ( ! -e $db ) {
	open  DBASE, ">$db" or die $!;
	print DBASE ""; 
	close DBASE;
}

## get every loaded module name
open PROC, "</proc/modules" or die $!;

my @modules;
while (<PROC>) { 

	if ( $_ =~ m/(.+)\ (\d+)\ (\d+)\ (.+)\ (.+)/ ) {
		push( @modules, $1 );
	}

}

close PROC;

## discard blacklisted modules
my $n = 0; my @ignored;

for (my $i=0; $i<@modules; $i++) {
	foreach ( @blacklist ) {
		if ( $modules[$i] eq $_ ) {
			splice( @modules, $i, 1 ); $n++;
			push ( @ignored, $_ );
			msg("Ignoring: $_", 0);
		}
	}
}

## obtain previous (old) modules
open  DBASE, "<$db" or die $!; my @oldmodules = <DBASE>; close DBASE;

## write file of the modules currently loaded if
## they do not already exist in the database file
open  DBASE, ">>$db" or die $!;

foreach ( @modules ) {

	if ( ! grep {/^$_$/} @oldmodules ) {
		msg("New module: $_", 1);
		print DBASE "$_\n" or die $!;
		
	}
	
}

close DBASE;

## verbose information (do not display output for cronjob use)
if ( $n gt 0 ) {
	msg( @modules . "/" .  (@modules + @ignored) . " being tracked", 2);
	msg("     Ignored modules (@ignored)", 0);

} else {
	msg( @modules . " modules being tracked", 2);

}
