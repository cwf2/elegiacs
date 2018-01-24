# ovid ex ponto parser
#
# Chris Forstall
# 24-01-2012
#
# input is the perseus file Perseus_text_2008.01.0493.xml
# NB this is not the same as the file you get with the
# Classics batch download.  In that one some of the lines
# are run together.

use strict;
use warnings;

#
# NB lines seem to end with CR only
#

my $pn;
my $bn;

my @line;
my @poem;
my @book;

my $filename = shift(@ARGV) 	|| "texts/perseus/Perseus_text_2008.01.0493.xml";

open (my $fh, "<", $filename)	|| die "can't open $filename: $!";

print STDERR "reading $filename\n";

while ( <$fh> )
{
	if (/<div1 type="book" n="(.+?)" /) {
				
		$bn = $1;
		@poem = ();
	}
	if (/<div2 type="poem" n="(.+?)"/) {
		
		$pn = $1;
		@line = ();
	}
	if (/<lb rend="displayNum" n="(.+?)".*?\/>(.+)\r/) {
	
		my ($ln, $line) = ($1, $2);
		
		chomp $line;
		
		$line =~ s/<note.+?<\/note>//g;
		$line =~ s/���/ - /g;
		$line =~ s/��//g;
		$line =~ s/<foreign lang="greek">(.+?)<\/foreign>/&beta_to_uni($1)/eg;
		$line =~ s/<\/?q.*?>/"/g;
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


sub beta_to_uni
{
	
	my @text = @_;
	
	for (@text)
	{
		
		s/(\*)([^a-z ]+)/$2$1/g;
		
		s/\)/\x{0313}/ig;
s/\(/\x{0314}/ig;
	s/\//\x{0301}/ig;
	s/\=/\x{0342}/ig;
	s/\\/\x{0300}/ig;
	s/\+/\x{0308}/ig;
	s/\|/\x{0345}/ig;
	
	s/\*a/\x{0391}/ig;	s/a/\x{03B1}/ig;  
	s/\*b/\x{0392}/ig;	s/b/\x{03B2}/ig;
	s/\*g/\x{0393}/ig; 	s/g/\x{03B3}/ig;
	s/\*d/\x{0394}/ig; 	s/d/\x{03B4}/ig;
	s/\*e/\x{0395}/ig; 	s/e/\x{03B5}/ig;
	s/\*z/\x{0396}/ig; 	s/z/\x{03B6}/ig;
	s/\*h/\x{0397}/ig; 	s/h/\x{03B7}/ig;
	s/\*q/\x{0398}/ig; 	s/q/\x{03B8}/ig;
	s/\*i/\x{0399}/ig; 	s/i/\x{03B9}/ig;
	s/\*k/\x{039A}/ig; 	s/k/\x{03BA}/ig;
	s/\*l/\x{039B}/ig; 	s/l/\x{03BB}/ig;
	s/\*m/\x{039C}/ig; 	s/m/\x{03BC}/ig;
	s/\*n/\x{039D}/ig; 	s/n/\x{03BD}/ig;
	s/\*c/\x{039E}/ig; 	s/c/\x{03BE}/ig;
	s/\*o/\x{039F}/ig; 	s/o/\x{03BF}/ig;
	s/\*p/\x{03A0}/ig; 	s/p/\x{03C0}/ig;
	s/\*r/\x{03A1}/ig; 	s/r/\x{03C1}/ig;
	s/s\b/\x{03C2}/ig;
	s/\*s/\x{03A3}/ig; 	s/s/\x{03C3}/ig;
	s/\*t/\x{03A4}/ig; 	s/t/\x{03C4}/ig;
	s/\*u/\x{03A5}/ig; 	s/u/\x{03C5}/ig;
	s/\*f/\x{03A6}/ig; 	s/f/\x{03C6}/ig;
	s/\*x/\x{03A7}/ig; 	s/x/\x{03C7}/ig;
	s/\*y/\x{03A8}/ig; 	s/y/\x{03C8}/ig;
	s/\*w/\x{03A9}/ig; 	s/w/\x{03C9}/ig;
	
	}

return wantarray ? @text : $text[0];
}
