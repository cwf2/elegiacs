use strict;
use warnings;

use Storable;
use File::Spec::Functions;

my @dataset = qw/20l-fair stichic/;

my $home = (getpwuid($<))[7];
my $path_data = catfile($home, 'elegiacs', 'data');

my %wcount;
my %lcount;

for my $dataset (@dataset) {

	print STDERR "Reading $dataset\n";

	my %index = %{ retrieve(catfile($path_data, $dataset, 'index.bin')) };
	
	for my $id (keys %index) {

		my $meter = $index{$id}{METER};
		my $file_sample = catfile($path_data, $dataset, $meter, $id);

		open (FH, "<", $file_sample) or die "can't open $file_sample: $!";

		while (my $line = <FH>) {

			$line = lc($line);
			$line =~ tr/jv/iu/;

			my @word = split(/[^a-z]+/, $line);

			unless (@word) {
				
				print STDERR "$dataset:$id:$line\n";
				next
			}

			for my $word (@word) {

				next unless $word =~ /[a-z]/;
				$wcount{$word}{$meter} ++;
			}

			$lcount{$meter} ++;
		}

		close FH;		
	}
}

my $file_table = catfile("tables", "all_tokens");
open (my $fh, ">", $file_table) or die "Can't write $file_table: $!";

print $fh join("\t", ("token", keys %lcount)) . "\n";
	

for my $word (keys %wcount) {
	
	my @row = ($word);
	
	for my $meter (keys %lcount) {
		
		push @row, sprintf("%.4f", ($wcount{$word}{$meter} || 0)/$lcount{$meter});
	}
	
	print $fh join("\t", @row) . "\n";
}

close $fh;
