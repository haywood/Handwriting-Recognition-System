#!/usr/bin/perl -w

use strict;

my (@line,$wordIndex,$hostRoot,$localRoot,$filePath,$wordurls);

$hostRoot='http://www.iam.unibe.ch/~fkiwww/iamDB/data/words/';
$wordIndex='wordswithwriters.txt';
$wordurls='wordurls.txt';
$localRoot='words/';


open INDEX, $wordIndex;
open URLS, '>', $wordurls;

while (<INDEX>) {
    @line=split /\s+/;
    print URLS $hostRoot, $line[4], "\n";
}

close URLS;
close INDEX;

`wget --http-user=mhr2126 --http-passwd=eureka7 -x -nc -nH --cut-dirs=3 -i $wordurls`;
