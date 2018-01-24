# catullus parser
#
# Chris Forstall
# 13-01-2012
#
# input is the perseus catullus

use strict;
use warnings;

use XML::LibXML;

# this bit parses the xml document
#
# I copied it from the documentation on CPAN

my $parser = new XML::LibXML;

my $filename = shift(@ARGV) 	|| "texts/perseus/cat_lat.xml";

open (my $fh, "<", $filename)	|| die "can't open $filename: $!";

print STDERR "reading $filename\n";

my $doc = $parser->parse_fh( $fh );

close ($fh);

#
# read the parsed data and spit out only what we want
#
# - put the whole thing in an enclosing <text>
# - poem divisions with numbers
# - line divisions with numbers

print STDERR "writing output\n";
binmode STDOUT, ":utf8";

print "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
print "<text>\n";

for my $poem ( $doc->findnodes('//div1[@type="Elegies"]/div2[@type="Poem"]') ) {
	
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
		next if ($text eq "");
		
		print "\t\t<l n=\"$ln\">$text</l>\n";
	}
	print "\t</div>\n";
}

print "</text>\n";