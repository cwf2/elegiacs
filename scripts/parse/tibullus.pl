# tibullus parser
#
# Chris Forstall
# 25-01-2012
#
# input is the perseus tibullus

use strict;
use warnings;

#
# This is divided the old-fashioned way, into 3 books instead of 4 
#
# The Panegyricus Messallae will be left out, since it's not in elegiacs,
# but all the numbers will be kept as in the perseus file.

my $pn;
my $bn;

my @line;
my @poem;
my @book;

my $filename = shift(@ARGV) 	|| "texts/perseus/tibullus.el_lat.xml";

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
		@line = ();
	}
	if (/<lb type="displayNum" n="(.+?)"\/>(.+)\n/) {
	
		my ($ln, $line) = ($1, $2);
		
		chomp $line;

		$line =~ s/&mdash;/ - /g;
		$line =~ s/&[a-z]+;//g;
		$line =~ s/<\/?q>/"/g;
		$line =~ s/<.+?>//g;
		
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


