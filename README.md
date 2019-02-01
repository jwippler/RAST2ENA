# RAST2ENA

#### To Fix in this README
* fix URLs for ENA, Wikipedia, Webin, SPAdes, MPI Bremen
* test run scripts
* fix embl file examples below
* locus tags: check if ENA has requirements for that
* ConvertRAST2ENA.pl:
  * check print statement around lines 55
  * check print feature table header around lines 65
  * check removed /qualifiers and what was the reason for removing them
  * check if $organism_2_lines works!
  * what if there are other things in the RAST embl, apart from peg and rna?
* Write part about running ena validator

```  
command line to check feature keys in the RAST embl file:
$ cat *.embl |grep "^FT"|sed 's/   /:/g'|awk -F ":" '{print $1"\t"$2}'|sort -u
FT
FT      CDS
FT      RNA
FT      source
FT      tRNA
```
## Summary
This is a collection of Perl scripts and tips for converting [RAST](http://rast.nmpdr.org/) bacterial genome annotations to [ENA](http://www.ena.org)-compliant [EMBL](http://www.wikipedia.org/EMBL) files, and for submitting annotated microbial genomes to ENA in general.

_For additional scripts and tips check out [this](https://github.com/lsayaved/Hello-World) helpful repository as well._

I strongly recommend visiting [GFBio](https://gfbio.org) if you want to submit any type of biological data to public repositories!

## Usage

### 1. Create an ENA-compliant EMBL file

The first few lines of a typical RAST-annotated embl file look like this:
```
ID  NODE_194074+_length_2134_cov_19.863
AC
XX
```


However, an ENA submission file is rather supposed to look like this:
```
ID   XXX; XXX; linear; XXX; XXX; XXX; XXX.
XX
AC   ;
XX
AC * _NODE_194074+_length_2134_cov_19.863
PR   Project:PRJEB20554;
XX
DE   XXX
XX
```

The `XXX` fields will be replaced with proper values by ENA. `ConvertRAST2ENA.pl` takes your embl file from RAST and re-formats it for genome submission to ENA. It also fixes feature table qualifiers, adds locus tags and project ID, and removes some problematic qualifiers produced by RAST.

The qualifiers that will be removed are:
* /genome_md5 (not recognized by ENA)
* /project:
* /genome_id:

___________
Export your annotated genome from RAST as .embl file and run `ConvertRAST2ENA.pl`:
```bash
./ConvertRAST2ENA.pl your_rast_genome.embl output.embl ENAprojectID "organism" locus_tag "host" isolate
```
* How to get an ENAprojectID: register your submission at ENA ([Webin](https://www.ena.org))
* How to get a locus tag: _you_ decide what this is going to be!


**Important notes:**
* `ConvertRAST2ENA.pl` matches the contig ID lines produced by [SPAdes](http://www.spades.org) assemblies to identify the beginning of an embl entry in a multi-embl file. If your identifiers don't match, modify the pattern around line 36: `$line =~ /^ID\s{3}([\w+\.]+);.*/)` to match your own ID lines instead. Make sure to keep the parentheses `()` , which are not part of the pattern itself, but surround that part of the identifier, which used as contig ID in the output embl!

 [This website](https://www.regex101.com) is a fantastic resource to find and test out regular expressions to match your target.
* `ConvertRAST2ENA.pl` expects organisms that are symbionts of something else (we work with marine invertebrate-bacteria symbioses, [check it out](http://www.mpi-bremen.de)). If your organism is not host-associated, then you need to comment out a few lines in the script! (There are comments in the script itself, to help you with that: `CTRL+F` for "non-symbiont").

### 2. Validate embl file
Run ENA's embl validator script. Be sure to use the `-r` flag!

### 3. Fix any reported annotation errors

#### Error "Invalid amino acid"

Run `FixInvalidAminoAcidX.pl` to fix this error.

#### Error "Short introns"

Run `FitShortIntrons.pl` to fix this error.

## Issues
* If /organism="..." goes over more than two consecutive lines, it will cause `ConvertRAST2ENA.pl` to break. Since this is just a repeating line of the exact same text, you can easily fix this on the command line, e.g. with `sed`.

* Be careful when fixing internal stop codons. These might actually not be stop codons at all, but instead code for the special amino acids selenocysteine or pyrrolysine
