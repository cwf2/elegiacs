package LatinScansion;

##########################################
# 
#  functions common to scansion scripts
#
#  Chris Forstall
#  2010-06-06
#
#  revised 
#  2012-05-30
#  2012-07-19
#
##########################################

use strict;
use warnings;

BEGIN {

	require Exporter;

	our @ISA = qw(Exporter);
	our @EXPORT_OK = qw(sept_preprocess sept dhex pent hend chol sen priap sapph ascl gall adon gl ph replace_digraphs remove_digraphs syll_subdivide syll_markup consonantal_i syllables vowel_context);
}

use utf8;

our $VERSION=0.30;

return 1;

##########################################


#
# this sub was designed to help figure out
# vowel length by nature -- helps figure out
# which of several vowels in a word (whose
# natural lengths you know) a certain unknown
# length should be

sub vowel_context {
	
	# pass location of letter w/in syl in format "syl.pos" plus whole syl array

	my ($temp, @s) = @_;

	my ($syl, $s_offset) = (split /\./, $temp);

	# location of letter w/in line is that w/in syl...

	my $l_offset = $s_offset;
	
	# add length of any preceding syls

	for (my $i = 0; $i < $syl; $i++) { $l_offset += length($s[$i]) }

	# reconstitute the original line from syl array

	my $l = join("", @s);				

	#
	# the main bit
	#
	
	my ($word, $loc);
	
	# start at the beginning of the string, count word beginnings until you've passed
	#	the location of the letter you want
	
	for ($loc = 0; $loc < $l_offset;) {		

		# this matches word beginnings one at a time (global matching called in scalar context)
	
		$l =~ m/\b(\w+)/gc;
	
		$word = $1;
	
		# pos() returns the end of the last successful match, 
		#  i.e., the location of the last char of the word
		#  containing the letter we're looking for
	
		$loc = pos($l);			
	}						

	# (position of letter) - (( end of word ) - (length of word)) = position of letter w/in word

	my $offset = $l_offset - ($loc - length($word));

	return ($word, $offset);
}

sub replace_digraphs {
	
	my $l = shift;

	$l =~ s/q/qu/g;				# 'qu' is a digraph representing a single entity.
	$l =~ s/Q/Qu/g;				#
	$l =~ s/χ/ch/g;				# Greek digraphs
	$l =~ s/Χ/Ch/g;				#
	$l =~ s/φ/ph/g;				#
	$l =~ s/Φ/Ph/g;				#
	$l =~ s/θ/th/g;				#
	$l =~ s/Θ/Th/g;				#

	return $l;
}

sub remove_digraphs {

	my $l = shift;

	$l =~ s/qu/q/g;				# 'qu' is a digraph representing a single entity.
	$l =~ s/Qu/Q/g;				# 
	$l =~ s/ch/χ/g;				# Greek digraphs
	$l =~ s/Ch/Χ/g;				#
	$l =~ s/ph/φ/g;				#
	$l =~ s/Ph/Φ/g;				#
	$l =~ s/th/θ/g;				#
	$l =~ s/Th/Θ/g;				#

	return $l;
}

sub syll_subdivide {
	
	# assume input is one syllable, subdivide into onset, nucleus, coda

	my $s = $_[0];
	my ($ons, $nuc, $cod);

	if ( $s =~ m/
		(.*)                          # onset
		(ae|au|oe|ou|ui|[aeiouy])     # nucleus
		([^aeiouy]*)                  # coda
             /ix ) 
	{

		($ons, $nuc, $cod) = ($1, $2, $3);

		return ($ons, $nuc, $cod);
	}

  else { return undef };
}

sub syll_markup {

	my ($ons, $nuc, $cod, $w) = @_;
	my $syll;

	## new, quieter version ##

	$syll = "<seg type=\"syl\" weight=\"$w\">$ons<seg type=\"nuc\">$nuc</seg>$cod</seg>";


	#  $syll = '<seg type="syl" weight="' . $w . '">'
	#		.'<seg type="ons">' . $ons . '</seg>'
	#	        .'<seg type="nuc">' . $nuc . '</seg>'
	#	        .'<seg type="cod">' . $cod . '</seg>'
	#		.'</seg>';

	return $syll;
}

#
# syllabify a line
#

sub syllables {

	#  second, more complicated algorithm.  The idea is to match forwards, but start at the end.
	#  Punctuation is at first not considered, then reintroduced.

	#  a regex representing possible syllable-initial consonants and clusters

	my $onsetC = '(?:dr?)|(?:s?tr?)|(?:s?[ckpχφθ][rl]?)|(?:[bfg][rl]?)|(?:s?q)|(?:s?[lmn])|[smnrlv]';

	# argument is the line to parse

	my $l = shift;

	# simplify the orthography to one char per consonant

	$l = remove_digraphs($l);
	
	# these arrays hold syllables; one also includes punctuation

	my @s_plain;
	my @s_punct;

	# put all chars into an array so as to take them singly
	
	my @everything = split //, $l;		
	
	# this will mark the end of the preceding syl (to left)	
	
	my $place = $#everything;				

	# the working syl

	my $syl = "";

	# working syl is made up char by char from the right

	for (my $count = $#everything; $count > -1; $count--) {	

		# doesn't include non-letters
		if ( $everything[$count] =~ /\w/ ) {			

			# or h
      	if ($everything[$count] =~ /[^h]/i) {
			
        		$syl = lc($everything[$count]) . $syl;
			}
		}

		# as the string grows to the left, 
		# make sure it is still a phonemically allowable syllable 

		# if it has no vowels, it still needs to grow, skip to next step
		if ($syl =~ m/[aeiouy]/i) {		
	
			if  ( ($syl =~ m/^($onsetC)?(ae|au|oe|ou|[aeiouy])([^aeiouy]+)?$/i) and ( $count > 0)) {
	
				# As long as the string could still be a syllable, do nothing.
				# That is, all possible syllable-initial clusters should be assigned to the onset of 
				# the right-hand syllable.

				# There are no statements in this block.  The else block below used to be an "unless,"
				# but I think this will be easier to understand later.
			}

			else { 
	
				# if we arrive here then the working string contains at least one syl, 
				# probably also the final char of the preceding (left) one
	
				#  if the following (right) syl begins in s+C
				if ((($s_plain[0] || "") =~ /^(s)[^aeiouy]/i) and ($syl =~ /[aeiouy]$/i)){	
					
					#  remove the s and append it to the right of the current syl
					$s_plain[0] =~ s/^(s)//i;			
					$syl .= $1;

					#  same for the array that includes non-word chars
					$s_punct[0] =~ s/^(\W*s)//i;			
					
					#  extend the present syl to right
					#  by the number of chars removed from following syl
					$place += length($1);
				}

				if (($syl =~ /[aeiouy]$/i) and (($s_punct[0]||"") =~ /^m\W+(?:[aeoy]|[iu][^aeiouy])/i)) {	
				
					#  if the present syl ends in a vowel and following begins in m + \W + vowel
					#    then the present will ultimately be elided: move the m to the
					#    end of the present syl.
									
					#  remove the m and append it to the right of the current syl
					$s_plain[0] =~ s/^(m)//i;
					$syl .= $1;
							
					#  same for the array that includes \W
					$s_punct[0] =~ s/^(\W*m)//i;
					
					#  extend the present syl to right
					#  by the number of chars removed from following syl
					$place += length($1);
				}

				# remove from left of current syl the letter that
				# made it no longer a possible syl
        		$syl =~ s/^(\w)//;
				my $chr = $1;
				
				# if this is the first char
        		if ($count == 0) {

					unless  (($chr.$syl) =~ m/^(?:$onsetC|i)?(?:ae|au|oe|ou|[aeiouy])(?:[^aeiouy]+)?$/i) {

						# if it + working string does not make an allowable syl, then the first char must
						# constitute a syl unto itself
		
						if ($syl =~ s/^(s)(?=[^aeiouy])//i) { $chr .= $1; $count=1 }
	        
						# create two new syllables
	
						@s_plain = ($chr, $syl, @s_plain);						
						@s_punct = (join("",@everything[0..$count]), join("", @everything[$count+1..$place]), @s_punct);
						$count--;
					}
					
					# otherwise just reattach the first char to the working string
					else {

						@s_plain = ($chr.$syl, @s_plain);			
						@s_punct = (join("", @everything[0..$place]), @s_punct);
					}
        		}
        		else {
	
					# add working syl to "letters-only" array
					@s_plain = ($syl, @s_plain);
					
					# use marker to take slice of @everything for 
					# the syl that includes punctuation
					@s_punct = (join("", @everything[$count+1..$place]), @s_punct);	 
								
					# move placemarker to the present char	 
          		$place = $count;

					# add same to working syllable
					$syl = $1;					
				}
			}
		}
	}

	my $endpoint = $#s_punct;

	for (my $i = 0; $i <= $endpoint; $i++) {

		if ( $s_punct[$i] =~ s/([aeo])([\Wh]+[aeou].*)/$1/i ) {

			splice @s_punct, $i, 1, ($s_punct[$i], $2);
			$endpoint = $#s_punct;
		}


		if ( ($s_punct[$i] =~ m/gu$/i) and ($i < $endpoint)) {	
			# this is meant to remove syllable boundaries between gu|V
			if ( $s_punct[$i+1] =~ /^[aeiou]/i) {

				splice @s_punct, $i, 2, $s_punct[$i].$s_punct[$i+1];	# this should merge two array elements
				$endpoint = $#s_punct;
			}
		}

		# this block removes syl boundaries from diphthong eu
		# it seems to me that eu is a diphthong only where it
		# has a word boundary on one side or the other

		if ( ($s_punct[$i] =~ m/e$/i) and ($i < $endpoint)) {	
			
			if ( $s_punct[$i+1] =~ /^u/i) {

				if ( ($s_punct[$i] =~ m/\be$/i) or ($s_punct[$i+1] =~ m/^u\b/) ) {

					# this should merge two array elements
					splice @s_punct, $i, 2, $s_punct[$i].$s_punct[$i+1];	
					$endpoint = $#s_punct;
				}
			}
		}
		
		# this block catches instances of the diphthong
		# 'ui' in qui/s and its compounds

		if ( ($s_punct[$i] =~ m/\bcu$/i) and ($i < $endpoint)) {
						
			if ( $s_punct[$i+1] =~ /^i/ ) {
				
				# this should merge two array elements
				splice @s_punct, $i, 2, $s_punct[$i].$s_punct[$i+1];	
				$endpoint = $#s_punct;
			}
		}
		
		# this block catches instances of the diphthong
		# 'ui' in hic and compounds

		if ( ($s_punct[$i] =~ m/hu$/i) and ($i < $endpoint)) {
			if ( $s_punct[$i+1] =~ /^i/ ) {
				
				# this should merge two array elements

				splice @s_punct, $i, 2, $s_punct[$i].$s_punct[$i+1];
				$endpoint = $#s_punct;
			}
		}


		if ( $s_punct[$i] =~ s/(s)(\W+s)/$1/i ) {

			$s_punct[$i+1] = $1 . $s_punct[$i+1];
		}

		if ( ($s_punct[$i] =~ /h$/i) and ($i < $#s_punct) ) {

			$s_punct[$i] =~ s/(\W*h)$//i;
			$s_punct[$i+1] = $1 . $s_punct[$i+1];
		}

	}

	for my $i (0..$#s_punct) {

		$s_punct[$i] = replace_digraphs($s_punct[$i]);
	}

	return @s_punct;
}

sub consonantal_i {

	my @s = @_;
	my $endpoint = $#s;

	for (my $i = 0; $i <= $endpoint; $i++) {

		if ($s[$i] =~ /^(\w*)(\W+i)$/i) {

			my ($l,$r) = ($1, $2);
				
			# candidates syllables have i preceeded by a space
			# and the following syllable begins with a vowel

			if (($s[$i+1] || '') =~ /^[aeouy]/i) {

				# anything before the space appended to preceding (left) syl

				$s[$i-1] .= ($l || '');				
				
				# the i and space are added to following (right) syl
				
				$s[$i+1] = ($r || '') . $s[$i+1];

				# remove the syllable

				splice(@s, $i, 1);			

				# adjust both the counter and the endpoint for the loop

				$i--;
				$endpoint--;
			}
		}
	}

	return @s;
}

sub sept_preprocess {

	my ($n, @s) = @_;
	my $line;

	# if 15 syllables, scan as sept

	if ($#s == 14) {

		$line = &sept( $n, @s );
	}

	else {
		
		#  recursive attempt to reduce hypermetric lines

		if ($#s > 14) {							
		}
		
		# failure to scan

		print STDERR "[sept]$n\t" . join("|", @s) . "\n";		
		$line = join ("", @s);
	}

	return $line;
}

sub sept {

	# assume input has 15 syllables, begins w/ line number

	my ($n, @s) = @_;
	my $line;

	#
	# 7 feet of 2 syllables each
	#

	for (my $count = 0; $count < 13; $count +=2) {						

		# open foot tag

		$line .= '<seg type="foot" met="-u">';

		for my $offset (0,1) {

			my ($ons, $nuc, $cod) = &syll_subdivide( $s[$count + $offset] );

			if ($nuc eq "") {

				# if can't scan: warn,
				# return original line
				
				print STDERR "[can't subdivide $s[$count + $offset]]$n\t" . join("|", @s) . "\n";	
				$line = join ("", @s);

				return $line;
			}
			
			my $w = ($offset == 0) ? "-" : "u";

			$line .= &syll_markup( $ons, $nuc, $cod, $w );
		}
		
		# close foot tag
		
		$line .= '</seg>';
	}

	#
	# plus one anceps
	#
	
	# open foot tag
	
	$line .= '<seg type="foot" met="x">';

	my ($ons, $nuc, $cod) = &syll_subdivide( $s[14] );
	
	if ($nuc eq "") {
		
		# if can't scan: warn, return original line
	
		print STDERR "[can't subdivide $s[14]]$n\t" . join("|", @s) . "\n";				
		$line = join ("", @s);

		return $line;
	}

	$line .= &syll_markup( $ons, $nuc, $cod, '-' );

	$line .= '</seg>';
	
	return $line;
}

#
# dactylic hexameter
#

sub dhex {

	my ($n, @s) = @_;
	my $line;

	my @w = syl_weight(@s);

	my @foot;
	my @index;

	my $syl_count;
	my $ft_count;
	my $temp;

	my @possible = ();

	for my $a1 ('--', '-uu') { 					

		for my $a2 ('--', '-uu') { 					

			for my $a3 ('--', '-uu') { 

				for my $a4 ('--', '-uu') {

					push @possible, ($a1 . $a2 . $a3 . $a4 . '-uu--');

				}
			} 
		}
	}

	for my $i (0..$#w) {

		# index of non-elided syls

		unless ($w[$i] eq ' ') { push @index, $i; }
	}

	my @matches = meter_match(\@s, \@w, @possible);

	if ($#matches != 0) {

		@s = consonantal_i(@s);
		@w = syl_weight(@s);

		@matches = meter_match(\@s, \@w, @possible);
	}


	### output ###

	# if only one match is possible, proceed

	if ($#matches == 0) {

		for (0..$#index) {

			$w[$index[$_]] = substr($matches[0], $_, 1);
		}

		my $foot_markup = "";
		my $foot_metric = "";
		my $ft_count = 1;

		$line ="";

		for (my $i = 0; $i <= $#s; $i++) {

			my ($ons, $nuc, $cod) = &syll_subdivide( $s[$i] );											#

			$foot_metric .= ($w[$i] eq " " ? "" : $w[$i]);
			$foot_markup .= syll_markup($ons, $nuc, $cod, $w[$i]);

			if ($foot_metric =~ /-(?:-|(?:uu))/) {

				$line .= "<seg type=\"foot\" n=\"$ft_count\" met=\"$foot_metric\">$foot_markup</seg>";

				$foot_metric = "";
				$foot_markup = "";
				$ft_count++;
			}
		}
	}
	
	# otherwise fail
	
	else {						

		print STDERR "[hex]$n\t" . join("|", @s) . "\n";

		$line = join("", @s);
	}

	return $line;  
}

#
# hendecasyllables
#

sub hend {

	my ($n, @s) = @_;
	my $line;

	my @w = syl_weight(@s);

	my @foot;
	my @index;

	my $syl_count;
	my $ft_count;
	my $temp;

	my @possible = ();

	for my $a1 qw/- u/ { 					

		for my $a2 qw/- u/ { 					

			push @possible, ($a1 . $a2 . '-uu-u-u--');
		}
	}

	for my $i (0..$#w) {

		# index of non-elided syls

		unless ($w[$i] eq ' ') { push @index, $i; }		
	}

	my @matches = meter_match(\@s, \@w, @possible);

	### output ###

	# if only one match is possible, proceed

	if ($#matches == 0) {

		for (0..$#index) {

			$w[$index[$_]] = substr($matches[0], $_, 1);
		}

		$line ="";

		for (my $i = 0; $i <= $#s; $i++) {

			$line .=  syll_markup(syll_subdivide( $s[$i] ), $w[$i]);
		}
	}
	else {						# otherwise fail

		if ($#matches > 0) {

			my @array = (split //, '-uu-u-u--');

			for (2..10) {

				$w[$index[$_]] = shift @array;
			}
		}

		print STDERR "[hend:$#matches]$n\t";

		for (my $i=0; $i<=$#s; $i++) { 

			print STDERR $s[$i] . '{' . $w[$i] . '}' 
		}
		print STDERR "\n";

		$line = join("", @s);
	}

	return $line;  
}

#
# choliambics
#

sub chol {

	my ($n, @s) = @_;
	my $line;

	my @w = syl_weight(@s);

	my @foot;
	my @index;

	my $syl_count;
	my $ft_count;
	my $temp;

	my @possible = ();

	for my $a1 qw/- u/ { 					

		for my $a2 qw/- u/ { 					

			push @possible, ($a1 . '-u-' . $a2 . '-u-u---');
		}
	}

	for my $i (0..$#w) {
		
		# index of non-elided syls

		unless ($w[$i] eq ' ') { push @index, $i; }
	}

	my @matches = meter_match(\@s, \@w, @possible);

	### output ###

	# if only one match is possible, proceed

	if ($#matches == 0) {

		for (0..$#index) {

			$w[$index[$_]] = substr($matches[0], $_, 1);
		}

		$line ="";

		for (my $i = 0; $i <= $#s; $i++) {

			$line .=  syll_markup(syll_subdivide( $s[$i] ), $w[$i]);
		}
	}
	
	# otherwise fail
	
	else {						

		if ($#matches > 0) {

			my @array = (split //, '-u--u-u---');

			for (1..3,5..$#index) {

				$w[$index[$_]] = shift @array;
			}
		}

		print STDERR "[chol:$#matches]$n\t";

		for (my $i=0; $i<=$#s; $i++) { 

			print STDERR $s[$i] . '{' . $w[$i] . '}' 
		}
		print STDERR "\n";

		$line = join("", @s);
	}

	return $line;  
}

#
# glyconics
#

sub gl {

	my ($n, @s) = @_;
	my $line;

	my @w = syl_weight(@s);

	my @index;

	my @possible = ();

	for my $a1 qw/- u/ { 					

		for my $a2 qw/- u/ { 					

			push @possible, ($a1 . $a2 . '-uu-u-');
		}
	}

	for my $i (0..$#w) {
		
		# index of non-elided syls

		unless ($w[$i] eq ' ') { push @index, $i; }
	}

	my @matches = meter_match(\@s, \@w, @possible);

	### output ###
	
	# if only one match is possible, proceed

	if ($#matches == 0) {

		for (0..$#index) {

			$w[$index[$_]] = substr($matches[0], $_, 1);
		}

		$line ="";

		for (my $i = 0; $i <= $#s; $i++) {

			$line .=  syll_markup(syll_subdivide( $s[$i] ), $w[$i]);
		}
	}
	
	# otherwise fail
	
	else {

		if ($#matches > 0) {

			my @array = (split //, '-uu-u-');

			for (2..7) {

				$w[$index[$_]] = shift @array;
			}
		}

		print STDERR "[gl:$#matches]$n\t";

		for (my $i=0; $i<=$#s; $i++) { 

			print STDERR $s[$i] . '{' . $w[$i] . '}' 
		}
		print STDERR "\n";

		$line = join("", @s);
	}

	return $line;  
}

#
# pherecrateans
#

sub ph {

	my ($n, @s) = @_;
	my $line;

	my @w = syl_weight(@s);

	my @index;

	my @possible = ();

	for my $a1 qw/- u/ { 					

		for my $a2 qw/- u/ { 					

			push @possible, ($a1 . $a2 . '-uu--');
		}
	}
	
	# index of non-elided syls

	for my $i (0..$#w) {

		unless ($w[$i] eq ' ') { push @index, $i; }
	}

	my @matches = meter_match(\@s, \@w, @possible);

	### output ###
	
	# if only one match is possible, proceed

	if ($#matches == 0) {

		for (0..$#index) {

			$w[$index[$_]] = substr($matches[0], $_, 1);
		}

		$line ="";

		for (my $i = 0; $i <= $#s; $i++) {

			$line .=  syll_markup(syll_subdivide( $s[$i] ), $w[$i]);
		}
	}
	
	# otherwise fail
	
	else {						

		if ($#matches > 0) {

			my @array = (split //, '-uu--');

			for (2..6) {

				$w[$index[$_]] = shift @array;
			}
		}

		print STDERR "[ph:$#matches]$n\t";

		for (my $i=0; $i<=$#s; $i++) { 

			print STDERR $s[$i] . '{' . $w[$i] . '}' 
		}
		print STDERR "\n";

		$line = join("", @s);
	}

	return $line;  
}

#
# scansion of sapphics -- derived from chol
#

sub sapph {

	my ($n, @s) = @_;
	my $line;

	my @w = syl_weight(@s);

	my @index;

	my @possible = ();

	for my $a1 qw/- u/ { 					

		for my $a2 qw/- u/ { 					

			push @possible, ('-u-' . $a1 . '-uu-u-' . $a2);
		}
	}
	
	# index of non-elided syls

	for my $i (0..$#w) {

		unless ($w[$i] eq ' ') { push @index, $i; }
	}

	my @matches = meter_match(\@s, \@w, @possible);

	### output ###
	
	# if only one match is possible, proceed

	if ($#matches == 0) {

		for (0..$#index) {

			$w[$index[$_]] = substr($matches[0], $_, 1);
		}

		$line ="";

		for (my $i = 0; $i <= $#s; $i++) {

			$line .=  syll_markup(syll_subdivide( $s[$i] ), $w[$i]);
		}
	}
	
	# otherwise fail
	
	else {						

		if ($#matches > 0) {

			my @array = (split //, '-u--uu-u-');

			for (0..2,4..9) {

				$w[$index[$_]] = shift @array;
			}
		}

		print STDERR "[sapph:$#matches]$n\t";

		for (my $i=0; $i<=$#s; $i++) { 

			print STDERR $s[$i] . '{' . $w[$i] . '}' 
		}
		print STDERR "\n";

		$line = join("", @s);
	}

	return $line;  
}

#
# scansion of adonics -- copied from sen
#

sub adon {

	my ($n, @s) = @_;
	my $line;

	my @w = syl_weight(@s);

	my @index;

	# index of non-elided syls

	for my $i (0..$#w) {

		unless ($w[$i] eq ' ') { push @index, $i; }
	}

	my @matches = meter_match(\@s, \@w, '-uu--');

	### output ###

	# if only one match is possible, proceed

	if ($#matches == 0) {					

		for (0..$#index) {

			$w[$index[$_]] = substr($matches[0], $_, 1);
		}

		$line ="";

		for (my $i = 0; $i <= $#s; $i++) {

			$line .=  syll_markup(syll_subdivide( $s[$i] ), $w[$i]);
		}
	}

	# otherwise fail

	else {

		print STDERR "[adon:$#matches]$n\t";

		for (my $i=0; $i<=$#s; $i++) { 

			print STDERR $s[$i] . '{' . $w[$i] . '}' 
		}
		print STDERR "\n";

		$line = join("", @s);
	}

	return $line;  
}

#
# scansion of major asclepiadean -- copied from adon
#

sub asclp {

	my ($n, @s) = @_;
	my $line;

	my @w = syl_weight(@s);

	my @index;

	# index of non-elided syls

	for my $i (0..$#w) {

		unless ($w[$i] eq ' ') { push @index, $i; }		
	}

	my @matches = meter_match(\@s, \@w, '---uu--uu--uu-u-');

	### output ###

	# if only one match is possible, proceed

	if ($#matches == 0) {					

		for (0..$#index) {

			$w[$index[$_]] = substr($matches[0], $_, 1);
		}

		$line ="";

		for (my $i = 0; $i <= $#s; $i++) {

			$line .=  syll_markup(syll_subdivide( $s[$i] ), $w[$i]);
		}
	}

	# otherwise fail

	else {

		print STDERR "[asclp:$#matches]$n\t";

		for (my $i=0; $i<=$#s; $i++) { 

			print STDERR $s[$i] . '{' . $w[$i] . '}' 
		}
		print STDERR "\n";

		$line = join("", @s);
	}

	return $line;  
}

#
# scansion of priapeans -- derived from chol
#

sub priap {

	my ($n, @s) = @_;
	my $line;

	my @w = syl_weight(@s);

	my @foot;
	my @index;

	my $syl_count;
	my $ft_count;
	my $temp;

	my @possible = ();

	for my $a1 qw/- u/ { 					

		for my $a2 qw/- u/ { 					

			push @possible, ('-' . $a1 . '-uu-u-' .'-' . $a2 . '-uu--');
		}
	}

	# index of non-elided syls

	for my $i (0..$#w) {

		unless ($w[$i] eq ' ') { push @index, $i; }	
	}

	my @matches = meter_match(\@s, \@w, @possible);

	### output ###

	# if only one match is possible, proceed

	if ($#matches == 0) {	

		for (0..$#index) {

			$w[$index[$_]] = substr($matches[0], $_, 1);
		}

		$line ="";

		for (my $i = 0; $i <= $#s; $i++) {

			$line .=  syll_markup(syll_subdivide( $s[$i] ), $w[$i]);
		}
	}

	# otherwise fail

	else {

		if ($#matches > 0) {

			my @array = (split //, '--uu-u---uu--');

			for (0,2..8,10..$#index) {

				$w[$index[$_]] = shift @array;
			}
		}

		print STDERR "[priap:$#matches]$n\t";

		for (my $i=0; $i<=$#s; $i++) { 

			print STDERR $s[$i] . '{' . $w[$i] . '}' 
		}
		print STDERR "\n";

		$line = join("", @s);
	}

	return $line;  
}

#
# scansion of iambic senarii -- derived from chol
#

sub sen {

	my ($n, @s) = @_;
	my $line;

	my @w = syl_weight(@s);

	# index of non-elided syls

	my @index;

	for my $i (0..$#w) {

		unless ($w[$i] eq ' ') { push @index, $i; }
	}

	my @matches = meter_match(\@s, \@w, 'u-u-u-u-u-u-');

	### output ###

	# if only one match is possible, proceed

	if ($#matches == 0) {	

		for (0..$#index) {

			$w[$index[$_]] = substr($matches[0], $_, 1);
		}

		$line ="";

		for (my $i = 0; $i <= $#s; $i++) {

			$line .=  syll_markup(syll_subdivide( $s[$i] ), $w[$i]);
		}
	}

	# otherwise fail

	else {	

		print STDERR "[sen:$#matches]$n\t";

		for (my $i=0; $i<=$#s; $i++) { 

			print STDERR $s[$i] . '{' . $w[$i] . '}' 
		}
		print STDERR "\n";

		$line = join("", @s);
	}

	return $line;  
}

#
# scansion of galliambics -- copied from sen
#

sub gall {

	my ($n, @s) = @_;
	my $line;

	my @w = syl_weight(@s);

	# index of non-elided syls

	my @index;

	for my $i (0..$#w) {

		unless ($w[$i] eq ' ') { push @index, $i; }		
	}

	my @matches = meter_match(\@s, \@w, 'uu-u-u--uu-uuuu-');

	### output ###

	# if only one match is possible, proceed

	if ($#matches == 0) {

		for (0..$#index) {

			$w[$index[$_]] = substr($matches[0], $_, 1);
		}

		$line ="";

		for (my $i = 0; $i <= $#s; $i++) {

			$line .=  syll_markup(syll_subdivide( $s[$i] ), $w[$i]);
		}
	}

	# otherwise fail

	else {					

		print STDERR "[gall:$#matches]$n\t";

		for (my $i=0; $i<=$#s; $i++) { 

			print STDERR $s[$i] . '{' . $w[$i] . '}' 
		}
		print STDERR "\n";

		$line = join("", @s);
	}

	return $line;  
}

#
# "pentameter" line of an elegiac couplet
#

sub pent {

	my ($n, @s) = @_;
	my $line;

	my @w = syl_weight(@s);

	my @foot;
	my @index;

	my $syl_count;
	my $ft_count;
	my $temp;

	my @possible = ();

	for my $a1 ('--', '-uu') { 					

		for my $a2 ('--', '-uu') { 					

			for my $a3 ('--', '-uu') { 

				for my $a4 ('--', '-uu') {

					push @possible, ($a1 . $a2 . '-' . $a3 . $a4 . '-');

				}
			} 
		}
	}

	# index of non-elided syls

	for my $i (0..$#w) {

		unless ($w[$i] eq ' ') { push @index, $i; }
	}

	my @matches = meter_match(\@s, \@w, @possible);

	# if multiple scansions possible, assume feet 4,5 are dactyls

	if ($#matches > 0) {

		@possible = qw(-uu-uu--uu-uu- -uu----uu-uu- ---uu--uu-uu- ------uu-uu-);			

		@matches = meter_match(\@s, \@w, @possible);

		# if that doesn't work, check for consonantal i scanned as a vowel

		if ($#matches > 0) {    

			@s = consonantal_i(@s);
			@w = syl_weight(@s);

			@matches = meter_match(\@s, \@w, @possible);
		}
	}


	### output ###

	# if only one match is possible, proceed

	if ($#matches == 0) {

		for (0..$#index) {

			$w[$index[$_]] = substr($matches[0], $_, 1);
		}

		my $foot;
		my $ft_count = 1;
		my $ft_meter;

		for my $i (0..$#s) {

			$foot .= syll_markup(syll_subdivide($s[$i]), $w[$i]);

			unless ( $w[$i] eq ' ') { $ft_meter .= $w[$i] }

			if (($ft_count == 3) or ($ft_count == 6) ) {

				if ( $ft_meter eq '') {

					next;
				}
			}	
			elsif (($ft_meter ne '-uu') and ($ft_meter ne '--')) { 

				next;
			}

			$line .= "<seg type=\"foot\" n=\"$ft_count\" met=\"$ft_meter\">$foot</seg>";

			$ft_meter = "";
			$foot = "";
			$ft_count++;
		}
	}

	# otherwise fail

	else {	

		print STDERR "[pent]$n\t" . join("|", @s) . "\n";

		$line = join("", @s);
	}

	return $line;  
}

#
# calculate syllable quantities
#

sub syl_weight {

	my (@s) = @_;	

	my @weight;

	#
	# calculate syls heavy by position
	#
	
	for my $i (0..$#s) {
		
		# case 1: 
		# syllable ends in a vowel and 
		# next is a new word beginning in a vowel or h

		if (( $s[$i] =~ /[aeiou]m?$/i )  and ($i < $#s)
		and
		( $s[$i+1] =~ /^\W+h?[aeiouy]\W*[^aeiouy]?/i )) {	
			
			# syllable is elided 
			
			$weight[$i] = " ";					
		}
		
		# case 2:
		# syllable ends in a consonant
		
		elsif ( $s[$i] =~ /([^aeiouy])$/i ) {
			
			# syllable is heavy
			
			$weight[$i] = "-";
		}
		
		# case 3:
		# contains a diphthong
		
		elsif ( $s[$i] =~ /ae|au|eu|oe|ou/ ) {
			
			# syllable is heavy
			
			$weight[$i] = "-";
		}
		
		# case else:
		
		else {
			
			# unknown
			$weight[$i] = "x";
		}
	}

	return @weight;	
}

sub meter_match {

	my ($s_ref, $w_ref, @possible) = @_;

	my @matches;
	my $line;

	my @s = @{$s_ref};
	my @w = @{$w_ref};
	
	# a string of non-elided syls

	$line = join("", @w);					
	$line =~ s/ //g;
	$line = '^' . $line . '$';

	### test every possible line to see whether match is possible ###

	$line =~ s/x/\./g;

	for my $test (@possible) {

		if ( $test =~ /$line/ ) {

			push @matches, $test; 
		}
	}

	return @matches;
}
