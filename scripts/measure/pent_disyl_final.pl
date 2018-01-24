use strict;
use warnings;

use Storable;

use FindBin;
use lib "$FindBin::Bin/../modules";

use LatinScansion qw(syllables);

# specify file as cmd line arg

my $file = shift @ARGV;

#
# input
#

open (FH, "<:utf8", $file) || die "can't open $file: $!";

my @disyl;
my @other;

while ( my $line = <FH> ) {

	# this is faster than using an xml parser
	
	next unless ($line =~ /<l n="(\d+)">(.+)<\/l>/);
	
	my ($n, $text) = ($1, $2);
	
	# add this line to the sample for the correct meter,
	# add all lines to the mixed sample
	
	my $meter = ($n % 2 == 1) ? "hex" : "pent";

	# only check pent lines for now

	next unless $meter eq "pent";
	
	# temporarily strip trailing punctuation, space
	
	my $temp = $text;
	
	$temp =~ s/[^a-z]*$//i;
	
	# get last word, syllabify
	
	my @word = split (/\s+/, $temp);
	
	my @s = syllables($word[-1]);
	
	# sort by number of syllables 
	
	if ($#s == 1) { push @disyl, $text }
	else          { push @other, $text }

}

close FH;

#
# output
#

binmode STDOUT, ":utf8";

print "### pentameter lines ending in disyllables: ###\n\n";

for (@disyl) { print "$_\n" }

print "\n";

print "### pentameter lines not ending in disyllables: ###\n\n";

for (@other) { print "$_\n" }

print "\n";