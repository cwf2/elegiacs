use strict;
use warnings;

use File::Path qw(remove_tree make_path);
use Storable qw(nstore retrieve);

my $path_text = shift @ARGV || "texts/simple";

#
# create a data directory in the home folder
# - if the data is created in the dropbox folder
#   then you end up with a million files being
#   backed up.

my $home = (getpwuid($<))[7];
my $path_data = "$home/elegiacs/data/20l-full";

unless (-d "$home/elegiacs") {
	
	print STDERR "okay to create data directory $home/elegiacs? [Y/n]\n";
	
	my $response = <>;
	chomp $response;
	
	if ($response ne "" and lc($response) ne "y") {
		
		print STDERR "Quitting.\n";
		exit;
	}
}

my @file;

my %index;

#
# get the list of texts
#
# by default run only the elegies
# -- alternative is to run everything

my $textlist = "elegies";

if ( $textlist eq "elegies" ) {

	@file = qw/catullus.elegies.xml tibullus.elegies.xml propertius.xml
				ovid.amores.xml ovid.ars.xml ovid.remedia.xml ovid.heroides.xml 
				ovid.fasti.xml ovid.tristia.xml ovid.ex_ponto.xml
				martial.elegies.xml/;	
}
else {
	opendir(DH, $path_text) or die "can't open data dir: $!";
	
	@file = grep { /\.xml$/ } readdir DH;
	
	closedir DH;	
}

#
# clean/create the data directories
#

remove_tree($path_data);
make_path($path_data . "/pent" );
make_path($path_data . "/hex"  );
make_path($path_data . "/mixed");

#
# create samples
#

# this stores the sample number for each set

my %i		= ( "pent" => 0, "hex" => 0, "mixed" => 0 );
my %i_prev	= ( "pent" => 0, "hex" => 0, "mixed" => 0 );

for (@file) {
	
	# these save the name of the file, author, work

	my $work = $_;
	$work =~ s/\.xml$//;
		
	my $author = $_;
	$author =~ s/\..*//;
	
	my $file_text = $path_text . "/" . $_;

	# this holds lines to be divided into samples
		
	my %sample = ( "pent" => [], "hex" => [], "mixed" => [] );
				
	#
	# read the file
	#

	unless (open FH_TEXT, "<", $file_text) {
		
		warn "can't read $file_text; skipping";
		next;
	}

	while ( my $line = <FH_TEXT> ) {
	
		# this is faster than using an xml parser
		
		next unless ($line =~ /<l n="(\d+)">(.+)<\/l>/);
		
		my ($n, $text) = ($1, $2);
		
		# add this line to the sample for the correct meter,
		# add all lines to the mixed sample
		
		my $meter = ($n % 2 == 1) ? "hex" : "pent";
		
		push @{$sample{$meter}}, $text;
		push @{$sample{"mixed"}}, $text;
		
		# check to see whether any samples are 20 lines long;
		# if so, write the data file and increment the sample index
		
		for ("pent", "hex", "mixed") {

			if ($#{$sample{$_}} == 19) {
				
				my $sample_id = substr($_, 0, 1) . sprintf("%04i", $i{$_});
				
				# create a file for the sample
				
				my $file_data = $path_data . "/$_/" . $sample_id;
				
				open (FH_DATA, ">", $file_data) or die "can't write $file_data: $!";
				
				for (@{$sample{$_}}) {
					
					print FH_DATA $_ . "\n";
				}
				
				close FH_DATA;
				
				# increment sample number
				
				$i{$_}++;
				
				# clear working data
				
				$sample{$_} = [];
				
				# add this sample to the index
				
				$index{$sample_id} = { AUTHOR => $author, WORK => $work, METER => $_ };
			}
		}
	}
	close FH_TEXT;

	print STDERR join("\t", sprintf("%-10s", $work),
						($i{"mixed"}*20 - $i_prev{"mixed"}*20) . " lines", 
					  "(" . ($i{"hex"}  * 20 - $i_prev{"hex"}  * 20) . "h:"
						  . ($i{"pent"} * 20 - $i_prev{"pent"} * 20) . "p)\n");

	for ("hex", "pent", "mixed") { $i_prev{$_} = $i{$_} }
}

print STDERR ($i{"mixed"}*20) . " lines total\n";

nstore \%index, $path_data . "/index.bin";