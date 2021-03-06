#!/usr/bin/perl
use strict;
use warnings;
###########################################################
#
#   Author: Rajesh Patidar rajbtpatidar@gmail.com
#   Parse defuse, tophat-fusion, fusion cather result to make 
#    actionable fusions based on some rules.
#
###########################################################
my $mitchelman     = $ARGV[0];
my $omim	   = $ARGV[1];
my $tcga	   = $ARGV[2];
my $library        = $ARGV[3];
my $defuse         = $ARGV[4];
my $tophat         = $ARGV[5];
my $fusioncatcher  = $ARGV[6];
my $destination    = $ARGV[7];
print "#LeftGene\tRightGene\tChr_Left\tPosition\tChr_Right\tPosition\tSample\tTool\tRefDatabase\n";
my %REF;
unless (open(FH, "$mitchelman")){
        print STDERR "Can not open the file $mitchelman\n";
        exit;
}
while(<FH>){
        chomp;
        my @local =split("\t", $_);
	$REF{"$local[0]\t$local[1]"} = 'Mitchelman';
	$REF{"$local[1]\t$local[0]"} = 'Mitchelman';
}
close FH;
unless (open(FH, "$omim")){
	print STDERR "Can not open the file $omim\n";
	exit;
}
while(<FH>){
	chomp;
	my @local =split("\t", $_);
	if(exists $REF{"$local[0]\t$local[1]"}){
		$REF{"$local[0]\t$local[1]"} = $REF{"$local[0]\t$local[1]"}."; Omim";
	}
	else{
		$REF{"$local[0]\t$local[1]"} = "Omim";	
	}
	if (exists $REF{"$local[1]\t$local[0]"}){
		$REF{"$local[1]\t$local[0]"} = $REF{"$local[1]\t$local[0]"}."; Omim";
	}
	else{
		$REF{"$local[1]\t$local[0]"} = "Omim";
	}
}
close FH;
unless (open(FH, "$tcga")){
	print STDERR "Can not open the file $tcga\n";
	exit;
}
while(<FH>){
	chomp;
	my @local =split("\t", $_);
	if(exists $REF{"$local[0]\t$local[1]"}){
		$REF{"$local[0]\t$local[1]"} = $REF{"$local[0]\t$local[1]"}."; TCGA";
	}
	else{
		$REF{"$local[0]\t$local[1]"} = "TCGA";
	}
	if (exists $REF{"$local[1]\t$local[0]"}){
		$REF{"$local[1]\t$local[0]"} = $REF{"$local[1]\t$local[0]"}."; TCGA";
	}
	else{
		$REF{"$local[1]\t$local[0]"} = "TCGA";
	}

}
close FH;
###########################################################
###########################################################
unless (open(DEFUSE, "$defuse")){
	print STDERR "Can not open the file $defuse\n";
	exit;
}
unless (open(DEFUSE_OUT, ">$destination/$library.defuse.filtered.txt")){
	print STDERR "Can not open the file $destination/$library.defuse.filtered.txt\n";
	die $!;
}
while(<DEFUSE>){
	chomp;
	my @local =split("\t", $_);
	if($_ =~ /^cluster_id/){print DEFUSE_OUT "$_\n"; next}	
	if(exists $REF{"$local[30]\t$local[31]"}){
		print DEFUSE_OUT "$_\n";
		print "$local[30]\t$local[31]\tchr$local[24]\t$local[37]\tchr$local[25]\t$local[38]\t$library\tDefuse\t".$REF{"$local[30]\t$local[31]"}."\n";
	}
}
close DEFUSE;
close DEFUSE_OUT;
###########################################################
unless (open(TOP, "$tophat")){
        print STDERR "Can not open the file $tophat\n";
        exit;
}
unless (open(TOPHAT_OUT, ">$destination/$library.tophat.txt")){
	print STDERR "Can not open the file $destination/$library.tophat.txt\n";
	die $!;
}
while(<TOP>){
        chomp;
	my @local =split("\t", $_);
	if($_ =~ /Coordinate_left/){print TOPHAT_OUT "$_\n"; next}
	if(exists $REF{"$local[1]\t$local[4]"}){
		$local[3] = $local[3] + 1;
		$local[6] = $local[6] + 1;	
		print "$local[1]\t$local[4]\tchr$local[2]\t$local[3]\tchr$local[5]\t$local[6]\t$library\ttophatFusion\t".$REF{"$local[1]\t$local[4]"}."\n";
		print TOPHAT_OUT "$_\n";
	}

}
close TOP;
close TOPHAT_OUT;
###########################################################
unless (open(FC, "$fusioncatcher")){
        print STDERR "Can not open the file $fusioncatcher\n";
        exit;
}
unless (open(FC_OUT, ">$destination/$library.fusion-catcher.txt")){
	print STDERR "Can not open the file $destination/$library.fusion-catcher.txt\n";
	die $!;
}
while(<FC>){
        chomp;
	my @local =split("\t", $_);
	if($_ =~ /^Gene_1_symbol/){print FC_OUT "$_\n"; next}
	if(($local[2]  =~ /oncogene/ or $local[2]  =~ /known_fusion/ or $local[2]  =~ /cosmic/ or $local[2]  =~ /chimerdb2/ or $local[2]  =~ /ticdb/ or $local[2]  =~ /cgp/ or $local[2]  =~ /cell_lines/) and $local[3] <=0 and $local[4] >5 and $local[5] >3 and $local[6] >19){
		my @left  = split(":", $local[8]);
		my @right = split(":", $local[9]);
		if(exists $REF{"$local[0]\t$local[1]"}){
			print "$local[0]\t$local[1]\tchr$left[0]\t$left[1]\tchr$right[0]\t$right[1]\t$library\tFusionCatcher\t".$REF{"$local[0]\t$local[1]"}."\n";
		}
		else{
			print "$local[0]\t$local[1]\tchr$left[0]\t$left[1]\tchr$right[0]\t$right[1]\t$library\tFusionCatcher\t--\n";
		}
		print FC_OUT "$_\n";
	}
}
close FC;
close FC_OUT;
###########################################################
#Fusion_description  :  “oncogene” OR “known_fusion OR “cosmic” OR “chimerdb2” OR “ticdb” OR “cgp” OR “cell_lines”
#AND Counts_of_common_mapping_reads :  0
#AND Spanning_pairs : >5
#AND Spanning_unique_reads : >3
#AND Longest_anchor_found : > 19

#	0	Gene_1_symbol(5end_fusion_partner)		**
#	1	Gene_2_symbol(3end_fusion_partner)		**
###	2	Fusion_description
###	3	Counts_of_common_mapping_reads
###	4	Spanning_pairs
###	5	Spanning_unique_reads
###	6	Longest_anchor_found
#	7	Fusion_finding_method
#	8	Fusion_point_for_gene_1(5end_fusion_partner)	**
#	9	Fusion_point_for_gene_2(3end_fusion_partner)	**
#	10	Gene_1_id(5end_fusion_partner)
#	11	Gene_2_id(3end_fusion_partner)
#	12	Exon_1_id(5end_fusion_partner)
#	13	Exon_2_id(3end_fusion_partner)
#	14	Fusion_sequence
#	15	Predicted_effect
#	16	Predicted_fused_transcripts
#	17	Predicted_fused_proteins
