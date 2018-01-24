# ovid fasti parser
#
# Chris Forstall
# 18-01-2012
#
# copied from the martial parser
# input is perseus fasti

use strict;
use warnings;

#
# it's easier to read this file without an XML parser
#

my @book;
my @poem;

my $bn;
my $pn;
my @line;
my @ln;

my $filename = shift(@ARGV) 	|| "texts/perseus/ovid.fast_lat.xml";

open (my $fh, "<", $filename)	|| die "can't open $filename: $!";

print STDERR "reading $filename\n";

while ( <$fh> )
{
	if (/<div1 type="book" n="(\d+)">/) {
		
		$bn = $1;
		@line = ();
		@ln = ();
	}
	if (/<lb type="displayNum" n="(.+?)"\/>(.+)\n/) {
	
		push @ln, $1;
		
		my $line = $2 || "";
		
		$line =~ s/<note .+?>.+?<\/note>//g;
		$line =~ s/<\/?q>/"/g;
		$line =~ s/&mdash;/ - /g;
		$line =~ s/&[a-z]+;//g;
		$line =~ s/<.+?>//g;
		
		push @line, $line;
	}
	if (/<\/div1>/) {
		
		push @book, { BN => $bn, LN => [@ln], LINE => [@line] };
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
	@ln = @{$$_{LN}};
	@line = @{$$_{LINE}};
	
	print "\t<div type=\"book\" n=\"$bn\">\n";
	

	for (0..$#line) {
		print "\t\t<l n=\"$ln[$_]\">$line[$_]</l>\n";
	}
		
	print "\t</div>\n";
}
print "</text>\n";

print STDERR "Please see doc/ovid.fasti.patch.txt\n";