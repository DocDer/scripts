#!/usr/bin/perl -w
# ===============================================================================
# Script to generate a rarefaction type curve from
# read depth statistics in a transcriptome project.
#
#
# Joshua Der
# Original script published in Der, et. al. 2011. BMC Genomics. 12:99.
# Modified to remove bootstrapped resampling routine and accept multiple files.
# Input files should be formatted as "num_EST\tcluster_ID\n" without any headers.
# A directory with multiple input files is passed to the script.
# ===============================================================================
use strict;
use List::Util 'shuffle';
use Statistics::Descriptive;

#print usage
if (!$ARGV[0]) {
    print "USAGE: rarefaction.pl <directory containing files>";
    exit(1);
}

my $input_dir = $ARGV[0];
my $file = "";

print "\nSTARTING RAREFACTION ANALYSIS FOR FILES IN \'$input_dir\'...\n";
opendir (DIR, "$input_dir") or die "Couldn't open $input_dir directory, $!";
chdir DIR;
while ($file = readdir(DIR)) {
	if ($file =~ /^\./){next;}
	
	my @unigenes = ();
	my %unigene_EST_count = ();
	my @unigenes_by_frequency = ();
	my %seen = ();
	my $num_est = 0;
	my $num_unigenes = 0;

	# read the coverage file
    open (IN, "$file") or die "Couldn't open $file file, $!";
	print "READING FILE \'$file\'.\n";
	while (<IN>){
		# split the lines at tab
		my @read_counts = split (/\t/, $_);
		# store the ids in an array
		push @unigenes, $read_counts[1];
		# store the EST count in a hash
		$unigene_EST_count{$read_counts[1]} = $read_counts[0];
	}
	close IN;
	
	
	open (OUT, ">$file.rarefaction") || die ("Cannot open $file.rarefaction output file, $!");
	print OUT "reads\t$file.uni\n1\t1\n";
	# make a HUGE array of unigene ids with one element for each EST in the unigene 
	print "\tStoring unigene frequency information.\n";
	foreach my $unigene_id ( @unigenes ) {
		for (my $i = 1; $i <= $unigene_EST_count{$unigene_id}; $i++) {
			push @unigenes_by_frequency, $unigene_id;
		}
	}
	print "\tSampling the assembly.\n";
	# shuffle the huge unigene array
	@unigenes_by_frequency = shuffle(@unigenes_by_frequency);
	# run through the big list to generate the rarefaction output
	foreach my $unigene_id (@unigenes_by_frequency) {
		if (exists $seen{$unigene_id}) {
			$num_est++;
		}
		else {
			$seen{$unigene_id} = 1;
			$num_unigenes++;
			$num_est++;
		}
		if ($num_est % 1000 == 0) {print OUT "$num_est\t$num_unigenes\n"; print '.';}
	}
	if ($num_est % 1000 != 0) {print OUT "$num_est\t$num_unigenes\n";}
	close OUT;
	print "\nDONE WITH FILE \'$file\'.\n";
}
