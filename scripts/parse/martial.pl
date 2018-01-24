# martial parser
#
# Chris Forstall
# 13-01-2012
#
# input is the perseus martial

use strict;
use warnings;

use Data::Dumper;

#
# it's easier to read this file without an XML parser
#

my @book;
my @poem;

my $bn;
my $pn;
my @line;
my @ln;

my $filename = shift(@ARGV) 	|| "texts/perseus/martial_lat.xml";

open (my $fh, "<", $filename)	|| die "can't open $filename: $!";

print STDERR "reading $filename\n";

while ( <$fh> )
{
	if (/<div1 type="book" n="(\d+)">/) {
		
		$bn = $1;
		@poem = ();
	}
	elsif (/<div2 type="poem" n="(.+?)">/) {
		
		$pn = $1;
		@line = ();
		@ln = ();
	}
	if (/<lb type="displayNum" n="(.+?)"\/>(.+)\n/) {
	
		push @ln, $1;
		
		my $line = $2;
		
		$line =~ s/<foreign lang="greek">(.+?)<\/foreign>/&beta_to_uni($1)/eg;
		$line =~ s/&quot;/"/g;
		$line =~ s/&mdash;/ - /g;
		$line =~ s/&[a-z]+;//g;
		$line =~ s/\+//g;
		$line =~ s/<.+?>//g;
		
		push @line, $line;
	}
	if (/<\/div2>/) {

		push @poem, { PN => $pn, LN => [@ln], LINE => [@line] };
	}
	if (/<\/div1>/) {
		
		push @book, { BN => $bn, POEM => [@poem] };
	}
}

close ($fh);


#
# now print formatted output
#

# only some of martial's poems are elegiac, and they're
# not marked in the TEI.  Instead, I'll go over a printed
# text by hand, and include here a list of the poems to parse

my @list = qw/1.pr 1.1 1.7 1.10 1.17 1.27 1.35 1.41 1.49 1.52 1.53 1.54 1.61 1.64 1.66 1.69 1.72 1.77 1.82 1.84 1.86 1.89 1.94 1.96 1.99 1.102 1.104 1.106 1.109 1.113 1.115 1.117 2.pr 2.4 2.6 2.11 2.13 2.15 2.17 2.23 2.33 2.37 2.41 2.44 2.48 2.54 2.55 2.57 2.65 2.68 2.70 2.73 2.74 2.83 2.86 2.92 3.2 3.7 3.12 3.14 3.20 3.22 3.25 3.29 3.35 3.40 3.44 3.47 3.53 3.58 3.64 3.67 3.73 3.77 3.82 3.84 3.93 3.96 3.98 4.2 4.4 4.6 4.9 4.14 4.17 4.21 4.23 4.28 4.30 4.37 4.39 4.43 4.46 4.50 4.55 4.61 4.64 4.65 4.70 4.77 4.81 4.84 4.86 4.89 5.2 5.4 5.6 5.8 5.12 5.14 5.18 5.20 5.24 5.26 5.35 5.37 5.39 5.41 5.44 5.49 5.51 5.54 5.56 5.60 5.70 5.73 5.78 5.80 5.84 6.1 6.4 6.8 6.12 6.14 6.17 6.19 6.22 6.24 6.26 6.28 6.30 6.37 6.39 6.42 6.49 6.55 6.62 6.64 6.66 6.70 6.72 6.74 6.78 6.82 6.90 6.92 7.4 7.7 7.11 7.17 7.20 7.26 7.31 7.34 7.39 7.45 7.48 7.55 7.60 7.67 7.70 7.72 7.76 7.79 7.86 7.89 7.95 7.97 7.98 8.pr 8.2 8.5 8.10 8.16 8.19 8.25 8.35 8.38 8.40 8.42 8.44 8.52 8.54 8.61 8.64 8.66 8.69 8.72 8.76 8.79 8.81 9.1 9.5 9.9 9.11 9.19 9.27 9.33 9.40 9.42 9.44 9.52 9.57 9.62 9.75 9.77 9.87 9.90 9.98 10.3 10.5 10.7 10.9 10.20 10.22 10.24 10.30 10.35 10.38 10.40 10.47 10.49 10.52 10.55 10.62 10.65 10.67 10.72 10.74 10.76 10.78 10.83 10.87 10.90 10.92 10.98 10.100 10.102 10.104 11.1 11.6 11.13 11.15 11.18 11.24 11.31 11.35 11.40 11.51 11.58 11.59 11.61 11.63 11.66 11.72 11.75 11.77 11.80 11.88 11.98 11.100 11.106 12.pr 12.7 12.8 12.10 12.15 12.16 12.18 12.20 12.22 12.24 12.26 12.30 12.32 12.34 12.36 12.37 12.39 12.41 12.43 12.45 12.47 12.49 12.51 12.53 12.55 12.57 12.59 12.61 12.63 12.65 12.67 12.69 12.71 12.73 12.75 12.77 12.79 12.81 12.83 12.85 12.87 12.89 12.91 12.93 12.95 12.97 14.8 14.10 14.37 14.39 14.40 14.52 14.56 14.148 14.206/;

print STDERR "writing output\n";
binmode STDOUT, ":utf8";

print "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
print "<text>\n";

for (@book) {
	
	$bn = $$_{BN};
	@poem = @{$$_{POEM}};
	
	print "\t<div type=\"book\" n=\"$bn\">\n";
	
	for (@poem) {
		
		$pn = $$_{PN};
			
		next if ( grep { $_ eq "$bn.$pn" } @list );

		@ln = @{$$_{LN}};	
		@line = @{$$_{LINE}};
		
		print "\t\t<div type=\"poem\" n=\"$pn\">\n";

		for (0..$#line) {
			print "\t\t\t<l n=\"$ln[$_]\">$line[$_]</l>\n";
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
