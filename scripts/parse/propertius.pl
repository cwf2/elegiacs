# propertius parser
#
# Chris Forstall
# 25-01-2012
#
# input is the perseus propertius

use strict;
use warnings;

#
# the line numbers aren't the best;
# the size of some gaps can't be determined.
#
# since all the gaps omit an even number of
# lines, I'm just going to ignore them and
# number everything continuously for now.

my $ln;
my $pn;
my $bn;

my @line;
my @poem;
my @book;

my $filename = shift(@ARGV) 	|| "texts/perseus/prop_lat.xml";

open (my $fh, "<", $filename)	|| die "can't open $filename: $!";
binmode $fh, ":utf8";

print STDERR "reading $filename\n";

while ( <$fh> )
{
	if (/<div1 type="book" n="(.+?)"/) {
				
		$bn = $1;
		@poem = ();
	}
	if (/<div2 type="poem" n="(.+?)"/) {
		
		$pn = $1;
		
		$ln = 0;
		@line = ();
	}
	if (/<lb(n="(?:.+?)")?\/>(.+)/) {
	
		$ln = $1 || $ln + 1;
		
		my $line = $2;
		
		chomp $line;
		
		$line =~ s/&mdash;/ - /g;
		$line =~ s/&[lr]dquo;/"/g;
		$line =~ s/<.+?>//g;

		if ($line !~/[a-z]/) {
			$ln--;
			next;
		}
		
		push @line, { LN => $ln, TEXT => $line };
	}
	if (/<\/div2>/) {

		push @poem, { PN => $pn, LINES => [@line] };
	}
	if (/<\/div1>/) {
		
		push @book, { BN => $bn, POEMS => [@poem] };
	}
}

close ($fh);


#
# now print formatted output
#

print STDERR "writing output\n";
binmode STDOUT, ":utf8";

print "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
print "<text>\n";

for (@book) {
	
	$bn = $$_{BN};
	@poem = @{$$_{POEMS}};
	
	print "\t<div type=\"book\" n=\"$bn\">\n";
	
	for (@poem) {
		
		$pn = $$_{PN};
	
		@line = @{$$_{LINES}};
		
		print "\t\t<div type=\"poem\" n=\"$pn\">\n";

		for (@line) {
			
			print "\t\t\t<l n=\"$$_{LN}\">$$_{TEXT}</l>\n";
		}
		
		print "\t\t</div>\n";
	}

	print "\t</div>\n";
}
print "</text>\n";
