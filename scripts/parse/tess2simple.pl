#!/usr/bin/env perl

=head1 NAME

tess2simple.pl - turn Tesserae format into simple XML

=head1 SYNOPSYS

tess2simple.pl FILE

=head1 DESCRIPTION

Create a minimalist XML document in which each line of the original
.tess file is enclosed in a <l> tag with the line number as an attribute.
Any higher-level divisions become <div>s.

=head1 OPTIONS AND ARGUMENTS

=item B<--help>

Pring usage and exit.

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is tess2simple.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use XML::LibXML;

# initialize some variables

my $help = 0;

# get user options

GetOptions(
	'help' => \$help
);

# print usage if the user needs help

if ($help) {
	pod2usage(1);
}

# file to read from cmd line arg

my $file_in = shift @ARGV;

unless (defined $file_in and -r $file_in) {
	
	pod2usage(1);
}

my $xml = readTess($file_in);
print $xml->toString(2);

#
# subroutines
#

# read a .tess file and create a hierarchical structure
sub readTess {

	my $file = shift;
	my $xml = XML::LibXML->createDocument("1.0", "utf8");
	my $root = $xml->createElementNS("", "text");
	$xml->setDocumentElement($root);
		
	open(my $fh, '<:utf8', $file) or die "Can't read $file: $!";
	
	while (my $line = <$fh>) {
	
		next unless $line =~ /^<(.+?)>\s+(.+)/;
		
		my ($tag, $verse) = ($1, $2);
		
		$tag =~ s/.+\s//;

		my @div = split(/\./, $tag);
		my $lno = pop(@div); 
		
		my $parent = $root;
		
		if ($#div >= 0) {
			for my $divno (@div) {
				my @existing_divs = $parent->getChildrenByLocalName('div');
				if ($#existing_divs > -1 and 
						$existing_divs[-1]->getAttribute('n') eq $divno) {
					$parent = $existing_divs[-1];
				}
				else {
					my $new_div = XML::LibXML::Element->new('div');
					$new_div->setAttribute('n', $divno);
					$parent = $parent->appendChild($new_div);
				}
			}
		}
		
		my $l = XML::LibXML::Element->new('l');
		$l->setAttribute('n', $lno);
		$l->appendText($verse);
		$parent->appendChild($l);
	}
	
	return $xml;
}