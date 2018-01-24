use strict;
use warnings;

use File::Path qw(remove_tree make_path);
use File::Spec::Functions;
use Storable qw(nstore retrieve);

my $path_text = shift @ARGV || "texts/simple";

#
# create a data directory in the home folder
# - if the data is created in the dropbox folder
#   then you end up with a million files being
#   backed up.

my $home = (getpwuid($<))[7];
my $path_data = catfile($home, 'elegiacs', 'data', '20l-fair');

unless (-d $path_data) {

	print STDERR "creating data directory $path_data\n";	
}

#
# clean/create the data directories
#

remove_tree($path_data);
make_path(catdir($path_data, 'epent' ));
make_path(catdir($path_data, 'ehex'  ));
make_path(catdir($path_data, 'emixed'));

#
# get the list of texts
#
# by default run only the elegies
# -- alternative is to run everything

my @file;

my %index;

my $lines_total;

my $textlist = "elegies";

if ( $textlist eq "elegies" ) {
	
	@file = qw/catullus.elegies.xml tibullus.elegies.xml propertius.elegies.xml
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
# read in the text files
#

my %sample;
my %lcount;

for (@file) {
	
	# these save the name of the file, author

	my $author = $_;
	$author =~ s/\..*//;
	
	my $file_text = catfile($path_text, $_);

	print STDERR "reading $file_text\n";

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
		
		my $meter = ($n % 2 == 1) ? "ehex" : "epent";
		
		push @{$sample{$author}{$meter}},  $text;
		push @{$sample{$author}{"emixed"}}, $text;
		
		$lcount{$author}{$meter}++;
		$lcount{$author}{"emixed"}++;
	}

	close FH_TEXT;
}

#
# find the largest number of samples 
# that can be taken form all authors
#

my %max_samples;

for my $meter (qw/ehex epent emixed/) {
	
	for my $author (keys %lcount) {
		
		if (not defined $max_samples{$meter} or 
			$lcount{$author}{$meter} < $max_samples{$meter}) {
				
			$max_samples{$meter} = $lcount{$author}{$meter};
		}
	}
	
	$max_samples{$meter} = int($max_samples{$meter} / 20);
}

#
# randomize the order of the lines in each author-meter set
#

# this holds the current sample number for each meter

my %i = ( "ehex" => 0, "epent" => 0, "emixed" => 0 );


for my $author (keys %sample) {
	
	print STDERR "writing data for $author\n";
	
	for my $meter (qw/ehex epent emixed/) {

		# mix up the order of the lines
		
		@{$sample{$author}{$meter}} = sort { rand() <=> rand() } @{$sample{$author}{$meter}};
		
		# divide lines into 20-line samples for each meter
		
		for my $s (0..$max_samples{$meter}-1) {
			
			my $sample_id = sprintf("%s%03i", substr($meter, 0, 2), $i{$meter}++);
			my $file_data = catfile($path_data, $meter, $sample_id);
			
			open (FH_DATA, ">", $file_data) or die "can't open $file_data: $!";
			
			for my $l (0..19) {
				
				print FH_DATA $sample{$author}{$meter}[$s*20+$l] . "\n";
			}
			
			close FH_DATA;
			
			# add this sample to the index
			
			$index{$sample_id} = { AUTHOR => $author, WORK => "NA", METER => $meter };
		}
	}
}

nstore \%index, catfile($path_data, 'index.bin');