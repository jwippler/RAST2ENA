#!/usr/bin/perl -w
use strict;

my $usage = "scriptname.pl
             EMBL outfile
             ENAprojectID
             organism
             locus_tag
             host
             isolate\n
             WARNING: /organism qualifier may not be >2 lines long!\n";

my $EMBL = shift or die $usage;
my $out = shift or die $usage;
my $ENAprojectID = shift or die $usage;
# Name of the symbiont:
my $organism = shift or die $usage;
# Locus tag can be freely chosen by user
my $locus_tag = shift or die $usage;
# Name of the host, remove if non-symbiont:
my $host = shift or die $usage;
# Host specimen ID, remove if non-symbiont:
my $isolate = shift or die $usage;

my $contig;
my $tag_count=1;
my $organism_2_lines=0;

open (FILE, $EMBL);
open (OUT, '>', $out) or die "Could not create file '$out' $!";

while (my $line =<FILE>){
    #remove trailing newline characters:
    chomp $line;

    #match the ID line and get contig identifier
    if (($line =~ /^ID\s{3}([\w+\.]+);.*/)) {
        #assign contig identifier value to $contig:
        $contig = $1;
        #Print first line of embl file:
        #  ID   XXX; XXX; linear; XXX; XXX; XXX; XXX.
        print OUT "ID   XXX; XXX; linear; XXX; XXX; XXX; XXX.\n";
        #print next couple of lines of embl file, e.g.:
        #  XX
        #  AC   ;
        #  XX
        #  AC * _NODE_194074+_length_2134_cov_19.8639
        #  PR   Project:PRJEB20554;
        #  XX
        #  DE   XXX
        #  XX
        print OUT "XX\n
                   AC   \;\n
                   XX\n
                   AC \* _". $contig . "\n" . "XX\n
                   PR   Project:$ENAprojectID;\n
                   XX\n
                   DE   XXX\n
                   XX\n";
    }

    #print feature table header
    if ($line =~ /^FT   Key             Location\/Qualifiers/) {
       print OUT "$line\nFH\n";
    }

    if ($line =~ /^FT.*/) {
        #remove unwanted lines
        if ($line =~ /.*\/genome_md5=.*/) {
            next;
        }
        elsif ($line =~ /.*\/project=.*/) {
            next;
        }
        elsif ($line =~ /.*\/genome_id=.*/) {
            next;
        }
        # transl_table is added again further down, but at correct position
        elsif ($line =~ /.*\/transl_table=.*/) {
            next;
        }
        #add organism info
        elsif ($line =~ /.*\/organism=.*/) {
            # Modify if non-symbiont:
            print OUT "FT                   /organism=\"$organism\"\n
                       FT                   /host=\"$host\"\n
                       FT                   /isolate=\"$isolate\"\n";
            if ($line =~ /.*[^"]$/) {
            $organism_2_lines = 1;
            }
        }
        # If /organism is >1 line, skip line
        elsif ($organism_2_lines == 1) {
            $organism_2_lines = 0;
            next;
        }

        elsif ($line =~ /.*\/db_xref="SEED.*\.peg\.(\d+)"/) {
            print OUT "FT                   \/locus_tag=\"${locus_tag}_${tag_count}\"\n
                       FT                   /transl_table=11\n";
            $tag_count++;
        }
        elsif ($line =~ /.*\/db_xref="SEED.*\.rna\.(\d+)"/) {
            print OUT "FT                   \/locus_tag=\"${locus_tag}_${tag_count}\"\n";
            $tag_count++;
        }
        #print out any other lines of the FT block:
        else {
            print OUT "$line\n";
        }
    }
    #print the sequence block lines:
    if (($line =~ /^SQ.*/) || ($line =~ /^\s{5}.*/) || ($line =~ /^\/\/$/)) {
        print OUT "$line\n";
    }
}


close (OUT);
close (FILE);
