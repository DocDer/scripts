#!/usr/bin/perl -w
# USAGE: get_seq_len_stats.pl FILENAME.fasta ['yes' | 'no']
# NOTE: Summary statistics are calculated by default. To suppress the summary file, 
# append the above command with "no". Summary statistics requires the 
# Statistics::Descriptive perl module.

use strict;

my $seqfile = $ARGV[0];
unless (-e $seqfile) {die "File \'$seqfile\' does not exist.\nUSAGE: get_seq_len_stats.pl FILENAME.fasta ['yes' | 'no']";}
my $full_stats = $ARGV[1] || "yes";

my ($id,$seq) = ("","");
my @len;
open IN, "< $seqfile";
open OUT, "> $seqfile.len.txt";
while (<IN>){
	chomp;
	if (/>(\S+)/){
		# set the previous info
		unless ($id eq ""){
			my $len = length($seq);
			push (@len,$len) if ($full_stats eq "yes");
			print OUT "$id\t$len\n";
		}
		$id = $1;
		$seq = "";
	} else {
		$seq .= $_;
	}
}
# deal with the last squence
my $len = length($seq);
push (@len,$len) if ($full_stats eq "yes");
print OUT "$id\t$len\n";
close OUT;

# Calculate the summary stats
if ($full_stats eq "yes"){
	use Statistics::Descriptive;

	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data(@len);
	my $seqcount = $stat->count();
	my $mean = sprintf("%.2f", $stat->mean());
	my $median = sprintf("%.2f", $stat->median());
	my $variance = sprintf("%.2f", $stat->variance());
	my $stdev = sprintf("%.2f", $stat->standard_deviation());
	my $mode = sprintf("%.2f", $stat->mode());
	my $min = sprintf("%.2f", $stat->min());
	my $max = sprintf("%.2f", $stat->max());
	my $sum = sprintf("%.0f", $stat->sum());
	my $mb = sprintf("%.2f", $sum/1000000);

	# Get the N50 length 
	my @sorted_len = sort {$b <=> $a} @len;
	my $cumulative = 0;
	my $count = 0;
	while ($cumulative <= ($sum * .5) ){
		$cumulative += shift @sorted_len;
		$count++;
	}
	my $L50 = shift @sorted_len;
	my $N50 = $count;
	$cumulative += $L50;
	$count++;

	# Get the N90 length
	while ($cumulative <= ($sum * .90) ){
		$cumulative += shift @sorted_len;
		$count++;
	}
	my $L90 = shift @sorted_len;
	my $N90 = $count;
	$cumulative += $L90;
	$count++;	

	# Get the N95 length
	while ($cumulative <= ($sum * .95) ){
		$cumulative += shift @sorted_len;
		$count++;
	}
	my $L95 = shift @sorted_len;
	my $N95 = $count;
	$cumulative += $L95;
	$count++;


	open OUT, ">$seqfile.seq_stats.txt";
	print OUT "SeqFile\tSeqCount\tMean_len\tStDev\tMedian\tMode\tN50\tL50\tN90\tL90\tN95\tL95\tMin\tMax\tSum\tMbp\n";
	print OUT "$seqfile\t$seqcount\t$mean\t$stdev\t$median\t$mode\t$N50\t$L50\t$N90\t$L90\t$N95\t$L95\t$min\t$max\t$sum\t$mb\n";
	close OUT;
}

exit;
