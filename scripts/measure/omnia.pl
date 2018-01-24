# omnia.pl
#
# measure a bunch of features and make a table
#
# Chris Forstall
# 2012-01-26
# revised 2013-09-10

use strict;
use warnings;

use Storable;
use File::Path qw/make_path remove_tree/;
use File::Spec::Functions;

my $home = (getpwuid($<))[7];
my $path_data = catfile($home, 'elegiacs', 'data');

my $dataset = shift @ARGV;

unless (defined $dataset) { 

	die "please specify dataset";
}

my @ngrams = qw/r e a m n t re er am um nt/;

my $vowel = qr/ae|oe|au|[aeiouy]/;
my $cons  = qr/th|ph|ch|[bcdfghklmnpqrstxz]/;

#
# features
#

my @features = (

	featuremodule->new(['wc', 'wl'], \&word_length),
	featuremodule->new([map {"c_$_"} @ngrams],  \&ngram_count, {ngram=>\@ngrams}),
	featuremodule->new([qw/con vow/], \&syllable_count),
	featuremodule->new('fin', \&final_disyllable),
);

#
# clean a space to work in
#

$path_data = catfile($path_data, $dataset);

#
# load the index
# 

my %index = %{ retrieve(catfile($path_data, 'index.bin')) };

my %uniq_author;
my %uniq_work;

#
# read each sample and calculate word length
#

for my $sample_id (keys %index) {
	
	my $author = $index{$sample_id}{AUTHOR};
	my $work = $index{$sample_id}{WORK};
	my $meter = $index{$sample_id}{METER};

	$uniq_author{$author} = 1;
	$uniq_work{$work} = 1;
	
	my $file_sample = catfile($path_data, $meter, $sample_id);
	
	my $text;
	
	open (FH, "<", $file_sample) or die "can't open $file_sample: $!";
	
	while (my $line = <FH>) {
	
		$line = lc($line);
		$line =~ tr/jv/iu/;
		
		$text .= $line;
	}
	
	close FH;
	
	for my $feat (@features) {
	
		push @{$index{$sample_id}{DATA}}, $feat->calc($text);
	}
}

# print the table

my $file_table = catfile('tables', $dataset);
export_table($file_table);

#
# subroutines
# 

sub clean_path {

	my $path_data = shift;
	
	if (-d $path_data) {

		print STDERR "cleaning $path_data\n";
		remove_tree($path_data);
	}
	else {
		
		print STDERR "creating $path_data\n";
	}
	
	make_path($path_data);
}

#
# print the table
#

sub export_table {
	
	my $file_table = shift;

	open (FH, ">", $file_table) || die "can't write to $file_table: $!";

	my @header = qw/sample author meter/;

	for my $feature (@features) {

		my $head = $feature->head;
	
		if (ref($head) eq 'ARRAY') {
	
			push @header, @$head;
		}
		else {
	
			push @header, $head;
		}
	}

	print FH join("\t",  @header) . "\n";

	for (keys %index) {
	
		my @row = (
			$_,
			$index{$_}{AUTHOR},
			$index{$_}{METER},
		);
			
		for my $val (@{$index{$_}{DATA}}) {

			if (ref($val) eq 'ARRAY') {

				push @row, @$val;
			}
			else {

				push @row, $val;
			}
		}
	
		print FH join("\t", @row) . "\n";
	}

	close FH;
}

sub tokenize {

	my $text = shift;
	
	my @tokens = grep {/[a-z]/} split(/[^a-z]+/, $text);
	
	if ($#tokens < 0) {
	
		print STDERR "tokenize: can't tokenize!\n$text\n";
	}
	
	return @tokens;
}

sub word_length {

	my $text = shift;
	my @tokens = tokenize($text);
	
	my $count;
	my $length;
	
	for (@tokens) {
	
		$count ++;
		$length += length($_);
	}
	
	return [$count, $length];
}

sub ngram_count {

	my $text = shift;
	
	my @pat = @ngrams;
	
	for (@pat) {
		
		if (/(.)(.+)/) { $_ = "$1(?=$2)" }
		
		$_ = qr/$_/;
	}
	
	my %count;
	
	for (0..$#pat) {
		
		my @hits = ($text =~ /$pat[$_]/g);
			
		$count{$ngrams[$_]} += scalar(@hits);
	}
	
	return [@count{@ngrams}];
}

sub syllable_count {

	my $text = shift;
	
	$text =~ s/qu/q/g;
		
	my @vowels     = ($text =~ /$vowel/g);		
	my @consonants = ($text =~ /$cons/g);
	
	return [scalar(@vowels), scalar(@consonants)];
}

sub final_disyllable {

	my $text = shift;
	
	my @lines = split(/\n/, $text);
	
	my $count;
	
	for my $line (@lines) {
	
		my @tokens = tokenize($line);
		
		my @vowels = ($tokens[-1] =~ /$vowel/g);
		
		$count += scalar(@vowels);
	}
	
	return $count;
}

#
# asdf
#

package featuremodule;

sub new {

	my ($package, $head, $calc, $opt) = @_;	

	my $self = {
		_head => $head,
		_calc => $calc,
		_opt  => $opt
	};
	
	bless $self, 'featuremodule';
	
	return $self;
}

sub head {

	my $self = shift;
	
	return $self->{_head};
}

sub calc {

	my ($self, $data) = @_;
	
	return &{$self->{_calc}}($data, $self->{_opt});
}
