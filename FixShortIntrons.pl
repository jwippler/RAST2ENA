#!/usr/bin/perl -w
use strict;
use warnings;
use 5.010;
use Data::Dumper qw(Dumper);

# This script takes VAL_ERROR.txt output from embl validator, looks for errors of the type "ERROR: Intron usually expected to be at least 10 nt long" and fixes them in the embl file
# Tested with VAL_ERROR.txt output from validator embl-api-validator-1.1.263.jar
# example command line: 
# $ ./FixShortIntrons.pl EMBL VAL_ERROR.txt outfile


my $usage = "scriptname.pl EMBL outfile VAL_ERROR.txt\n";
my $EMBL = shift or die $usage;
my $out = shift or die $usage;
my $VAL_ERROR = shift or die $usage;

my @error_lines; # array to hold all line numbers that give errors
my $line_counter = 0; # count current lines read from embl file

# read the VAL_ERROR.txt file and get all embl line numbers that produce errors of the type "Intron usually expected to be at least 10 nt long"
open (VAL_ERROR, $VAL_ERROR);

while (my $line =<VAL_ERROR>){
    #remove trailing newline characters
    chomp $line;
    if (($line =~ /ERROR: Intron usually expected to be at least 10 nt long.*line:\s([\d]+)\sof.*/)) {
        push @error_lines, $1;
    }
}

#say Dumper \@error_lines;
    
close (VAL_ERROR);

# convert array into hash, so value lookup is easier (also values, i.e. line numbers are unique, now - for example, if there are multiple introns per CDS the embl validator will thrugh as many errors as there are introns in each CDS!):
my %error_lines_hash = map { $_ => 1 } @error_lines;

# read the embl file and fix error error_lines
open (EMBL, $EMBL);
open (OUT, '>', $out) or die "Could not create file '$out' $!";

while (my $line =<EMBL>){
    #remove trailing newline characters
    chomp $line;
    $line_counter++;
    if (exists($error_lines_hash{$line_counter})){
        #print "Counter variable was found in hash!\n";
        print OUT "$line\nFT                   /pseudo\n";
    }
    else{
        print OUT "$line\n";
    }
}

#print "Number of lines is: $line_counter\n";
#say $#error_lines;
close (OUT);
close (EMBL);








