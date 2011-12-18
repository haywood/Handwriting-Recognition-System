#!/usr/bin/perl -w

use strict;

my(@line,%formCount,@wordRecords,%formSet);
my($writer,$form,$line,$word,$file,$text);

open FORMS, 'forms.txt';

while (<FORMS>) {
    if (m/^[^#]/) {
        @line=split /\s+/;
        $formCount{$line[1]}++;
        $formSet{$line[0]}=$line[1];
    }
}

close FORMS;

open INDEX, '>wordswithwriters.txt';
open WORDS, 'words.txt';

while (<WORDS>) {
    if (m/^(([a-z]\d{2})-\d{3}[a-z]?)-(\d{2})-(\d{2})/) {
        @line=split /\s+/;
        $form=$1;
        $writer=$formSet{$form};
        if ($formCount{$writer} >= 10) {
            $line=$3;
            $word=$4;
            $file="$2/$form/$&.png";
            $text=$line[8];
            $text=$line[8];
            print INDEX $writer, ' ', $form, ' ', $line, ' ', $word, ' ', $file, ' ', $text, "\n";
        }
    }
}

close WORDS;
close INDEX
