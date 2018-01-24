# word_length.pl
#
# measure the average word length of samples
#
# Chris Forstall
# 2012-01-26

use strict;
use warnings;

use Storable;

my $home = (getpwuid($<))[7];
my $path_data = "$home/elegiacs/data";

my $dataset = shift @ARGV || die "please specify dataset";

$path_data .= "/$dataset";

#
# load the index
# 

my %index = %{ retrieve($path_data . "/index.bin") };

my %uniq_author;
my %uniq_work;

my %author_code;
my %work_code;
my %meter_code = ( "hex" => 0, "pent" => 1, "mixed" => 2 );

#
# read each sample and calculate word length
#

for my $sample_id (keys %index) {
	
	my $author = $index{$sample_id}{AUTHOR};
	my $work = $index{$sample_id}{WORK};
	my $meter = $index{$sample_id}{METER};

	$uniq_author{$author} = 1;
	$uniq_work{$work} = 1;
	
	open (FH, "<", "$path_data/$meter/$sample_id") || die "can't open $path_data/$meter/$sample_id: $!";
	
	# the number of words
	my $count;
	
	# the cumulative length of words
	my $length;
	
	# the number of consonants
	my $consonants;
	
	# the number of vowels/vowel-groups
	my $vowels;
	
	# the number of consonant clusters
	my $clusters;
	
	while (my $line = <FH>) {
			
		my @word = split(/[^a-z]+/, $line);
		
		for (@word) {
			
			next unless (/[a-z]/);
			
			$length += length($_);
			$count++;
			
			my $temp = $_;
			
			$vowels += scalar( s/[aeiou]+//g );
			$consonants += scalar( s/[^aeiou]//g );
								   
			$clusters += scalar( $temp =~ s/[^aeiou]{2,}//g );
		}
	}
	
	close FH;
	
	$index{$sample_id}{WORDLEN} = sprintf("%.2f", $length/$count);
	$index{$sample_id}{C_V} = sprintf("%.2f", $consonants/$vowels);
	$index{$sample_id}{CLUSTER} = sprintf("%.2f", $clusters/$count);
}

# create a number code for each author

my $i = 0;

print STDERR "Key to Authors:\n";

for (sort keys %uniq_author) {
	
	$author_code{$_} = $i++;
	
	print STDERR "$author_code{$_}\t$_\n";
}

# create a number code for each text

$i = 0;

print STDERR "\nKey to Works:\n";

for (sort keys %uniq_work) {
	
	$work_code{$_} = $i++;
	
	print STDERR "$work_code{$_}\t$_\n";
}

#
# print the table
#

open (FH, ">", "tables/$dataset") || die "can't write to tables/$dataset: $!";

print FH join("\t", qw/sample author work meter wl cv cc/, "\n");

for (sort keys %index) {
	
	print FH join("\t", $_,
		$author_code{$index{$_}{AUTHOR}},
		$work_code{$index{$_}{WORK}},
		$meter_code{$index{$_}{METER}},
		$index{$_}{WORDLEN},
		$index{$_}{C_V},
		$index{$_}{CLUSTER},
		"\n");
}

close FH;