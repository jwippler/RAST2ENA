#!/usr/bin/perl -w
use strict;
use warnings;

# Fixes error "ERROR: Invalid amino acid "x" in translation."

# Cause of the error are lower case x in /translation
# "x" signifies internal stop codons in RAST-annotated embl files
# CDS with internal stop codons need to have the qualifier /pseudo added
# CDS with the /pseudo qualifier may not have a /translation qualifier

# Tested with embl-api-validator-1.1.263.jar

my $usage = "scriptname.pl EMBL outfile\n";
my $EMBL = shift or die $usage;
my $out = shift or die $usage;

my $translation_start = 0;
my $translation_stop = 0;
my $translation_block = "";
my $amino_acids = "";
my $line_count = 0;
my $invalid_aa = "";

open (EMBL, $EMBL);
open (OUT, '>', $out) or die "Could not create file '$out' $!";

while (my $line =<EMBL>){
    $line_count ++;
    #remove trailing newline characters
    #chomp $line;
    # Check if a line contains the /translation qualifier, capture the start of the translation
    # Also check if the translation is contained in a single line
    if ($line =~ /(.*\/translation=".*\n)/) {
        $translation_start = 1;
        $translation_block = $1;
        # check if /translation is across a single line, and if yes, translation_block is done and print (TO DO: put in subroutine):
        if ($line =~ /.*"$/) {
            $amino_acids = $translation_block;
            $amino_acids =~ s/FT\s{19}\/translation="//g;
            $amino_acids =~ s/FT\s{19}//g;
            $amino_acids =~ s/"//g;
            $amino_acids =~ s/\n//g;
            if ($amino_acids =~ /[x]+/) {
                print "### Internal stop codon(s) \"x\" in line $line_count\n";
                print OUT "FT                   /pseudo\n";
                #print OUT "$translation_block";
                # Reset start and stop flags:
                $translation_start = 0;
                $translation_stop = 0;
                $translation_block = "";
                next;
            }
            else {
                print OUT "$translation_block";
                # Reset start and stop flags:
                $translation_start = 0;
                $translation_stop = 0;
                $translation_block = "";
                next;
            }
        }
    }
    # Catch the middle lines of the translation_block:
    elsif ($translation_start == 1 && $translation_stop == 0 && $line =~ /(^FT\s{19}\w+[^"]\n)/) {
        $translation_block .= $1;
        next;
    }
    # Catch the end of the translation_block:
    if ($translation_start == 1 && $translation_stop == 0 && $line =~ /(^FT\s{19}\w*"\n)/) {
        $translation_stop = 1;
        $translation_block .= $1;
        next;
    }
    # If translation_block started and ended, print to file:
    if ($translation_start == 1 && $translation_stop == 1) {
        # Now that the translation_block has been fully captured, check its IUPAC compliance:
        $amino_acids = $translation_block;
        $amino_acids =~ s/FT\s{19}\/translation="//g;
        $amino_acids =~ s/FT\s{19}//g;
        $amino_acids =~ s/"//g;
        $amino_acids =~ s/\n//g;
        if ($amino_acids =~ /[x]+/) {
            print "### Internal stop codon(s) \"x\" in line $line_count\n";
            print OUT "FT                   /pseudo\n";
            #print OUT "$translation_block";
            # Reset start and stop flags:
            $translation_start = 0;
            $translation_stop = 0;
            $translation_block = "";
        }
        else {
            print OUT "$translation_block";
            # Reset start and stop flags:
            $translation_start = 0;
            $translation_stop = 0;
            $translation_block = "";
        }
        #print OUT "### Flags re-set to 0, \$translation_block is now empty:\n### \"$translation_block\"\n";
    }
    if ($translation_start == 0 && $translation_stop == 0) {
        #print OUT "### This should be a non-translation_block line:\n";
        print OUT "$line";
    }
}


close (OUT);
close (EMBL);
