use strict;
use warnings;

use File::Path qw(remove_tree make_path);
use File::Spec::Functions;
use JSON;

my $path_text = shift @ARGV;

unless (defined $path_text) { 
	$path_text = catfile('texts', 'tesserae');
}


my $path_data = catfile('data', 'stichic');

unless (-d $path_data) {

	print STDERR "creating data directory $path_data\n";	
}

#
# clean/create the data directories
#

remove_tree($path_data);
make_path($path_data);
make_path(catdir($path_data, 'hex'));

#
# get the list of texts
#

my %index;

my $lines_total;
	
my @file = get_files($path_text);

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
	
		chomp($line);
		
		next unless ($line =~ /<.+?>\s+(.+)/);
		
		my $line = $1;
		
		$line = lc($line);
		
		next unless $line =~ /[a-z]/;
		
		push @{$sample{$author}}, $line;
		
		$lcount{$author} ++;
	}

	close FH_TEXT;
}

#
# find the largest number of samples 
# that can be taken form all authors
#

my $max_samples;

for my $author (keys %lcount) {
		
	if (not defined $max_samples or $lcount{$author} < $max_samples) {
				
		$max_samples = $lcount{$author};
	}
}

$max_samples = int($max_samples / 20);

print STDERR "samples = $max_samples\n";

#
# randomize the order of the lines in each author
#

my $i = 0;

for my $author (keys %sample) {
	
	print STDERR "writing data for $author\n";
	
	# mix up the order of the lines
		
	@{$sample{$author}} = sort { rand() <=> rand() } @{$sample{$author}};
		
	# divide lines into 20-line samples
		
	for my $s (0..$max_samples-1) {
			
		my $sample_id = sprintf("sh%03i", $i++);
		my $file_data = catfile($path_data, 'hex', $sample_id);
			
		open (FH_DATA, ">", $file_data) or die "can't open $file_data: $!";
			
		for my $l (0..19) {
				
			print FH_DATA $sample{$author}[$s*20+$l] . "\n";
		}
			
		close FH_DATA;
			
		# add this sample to the index
			
		$index{$sample_id} = { AUTHOR => $author, WORK => "NA", METER => 'hex' };
	}
}

#
# write the index
#

my $json = JSON->new;
$json = $json->pretty([1]);

open (my $fh_index, ">", catfile($path_data, 'index.json'));
print $fh_index $json->encode(\%index);


#
# subroutines
#

sub get_files {
	
	my $path_text = shift;

	opendir(DH, $path_text) or die "can't open data dir: $!";
	
	@file = grep { /\.tess$/ } readdir DH;
	# @file = grep { $_ !~ /catullus/ } @file;
	
	closedir DH;	
	
	return @file;
}