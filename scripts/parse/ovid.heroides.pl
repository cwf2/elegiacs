# ovid parser
#
# Chris Forstall
# 17-01-2012
#
# input is the perseus file ovid.am_lat.xml
# which contains the following, each in its own
# <text></text> node
#	amores
#	heroides
#	medicamina
#	ars amatoria
#	remedia amoris

use strict;
use warnings;

use XML::LibXML;

# this bit parses the xml document
#
# I copied it from the documentation on CPAN

my $parser = new XML::LibXML;

my $filename = shift(@ARGV) 	|| "texts/perseus/ovid.am_lat.xml";

open (my $fh, "<", $filename)	|| die "can't open $filename: $!";

print STDERR "reading $filename\n";

my $doc = $parser->parse_fh( $fh );

close ($fh);

#
# heroides
#

print STDERR "writing output\n";
binmode STDOUT, ":utf8";

print "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
print "<text>\n";	

for my $poem ( $doc->findnodes('//text[@n="Ep."]/body/div1[@type="poem"]') ) {
	
	my $pn = $poem->getAttributeNode('n')->to_literal;
	my $ln;
	
	print "\t<div type=\"poem\" n=\"$pn\">\n";
	
	for my $line ( $poem->findnodes('l') ) {
		
		if ( defined $line->getAttributeNode('n') ) {
			$ln = $line->getAttributeNode('n')->to_literal;
		} 
		else {
			$ln++;
		}
		
		my $text = $line->textContent;
		chomp $text;
		
		next if ($text eq "");
		
		print "\t\t<l n=\"$ln\">$text</l>\n";
	}
	print "\t</div>\n";
}

print "</text>\n";
