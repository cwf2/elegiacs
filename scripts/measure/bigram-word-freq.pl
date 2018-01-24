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
my $path_data = "$home/elegiacs/data/word-count";

unless (-d $path_data) {
	
	print STDERR "okay to create data directory $home/elegiacs? [Y/n]\n";
	
	my $response = <>;
	chomp $response;
	
	if ($response ne "" and lc($response) ne "y") {
		
		print STDERR "Quitting.\n";
		exit;
	}
	
	make_path($path_data);
}

my @file;

#
# get the list of texts
#
# by default run only the elegies
# -- alternative is to run everything

my $textlist = "elegies";

if ( $textlist eq "elegies" ) {

	@file = qw/catullus.elegies.xml tibullus.elegies.xml propertius.elegies.xml
				ovid.amores.xml ovid.ars.xml ovid.remedia.xml ovid.heroides.xml 
				ovid.fasti.xml ovid.tristia.xml ovid.ex_ponto.xml
				martial.elegies.xml/;	
}
else {
	opendir(DH, $path_text) or die "can't open text dir: $!";
	
	@file = grep { /\.xml$/ } readdir DH;
	
	closedir DH;	
}

#
# measure the number of words containing the bigram "er"
# and their counts
#

for my $bigram (qw/er is re es um/) {

	my %count;

	for (@file) {
	
		# these save the name of the file, author, work

		my $work = $_;
		$work =~ s/\.xml$//;
		
		my $author = $_;
		$author =~ s/\..*//;
	
		my $file_text = $path_text . "/" . $_;

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
		
			# simplify orthography
		
			$text = lc($text);
			$text =~ tr/jv/iu/;
		
			# count words
			
			my $meter = ($n % 2 == 1) ? "hex" : "pent";
		
			my @words = split(/[^a-z]+/, $text);
		
			for (@words) {
		
				if (/$bigram/) {
					$count{$author}{$_} += (s/$bigram//g);
				}
			}
		}
	
		close FH_TEXT;
	}

	for my $author (keys %count) {
		
		print STDERR "writing $path_data/$bigram~$author\n";
		open (FH_DATA, ">", "$path_data/$bigram~$author") || die "can't write to data dir: $!";
	
		for (sort {$count{$author}{$b}<=>$count{$author}{$a}} keys %{$count{$author}}) {

			print FH_DATA "$_\t$count{$author}{$_}\n";
		}
	
		close FH_DATA;
	}
}