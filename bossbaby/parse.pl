#!/usr/bin/perl -w
# generate episodes.json out of wikipedia tables
use strict;
use Data::Dumper;
use JSON;

my %data;

sub hashtitle {
    my $title = shift;
    $title = lc($title);
    $title =~ s/( |^)(a|the)( |$)//g;
    $title =~ s/[\.\s'’!,:&-]//g;
    return $title;
}

open(I, '<episodes.md');
my @titles;
my $epnum;
while (my $line = <I>) {
    chomp $line;
    if ($line =~ /^\|-|^\|}/) {
        # not empty
        if (scalar @titles and $epnum) {
            my $orgtitle = pop @titles;
            my $title = pop @titles;
            $data{hashtitle($orgtitle)} = { 'orgtitle' => $orgtitle, 'title' => $title, 'episode' => $epnum };
        }
        @titles = ();
        next;
    }

    my @parts = split(/\|/, $line);

    if ($line =~ /SERIA/) {
        @titles = ();
        $epnum = undef;
        next;
    }

    if ($line =~ /CCE2FF/) {
        $epnum = int(pop @parts);
        next;
    }

    $line =~ s/.*\|\s*|''|<.*|\s+$//g;
    push @titles, $line;
}
close I;

# write mapping to json
open (OUT, ">episodes.json");
print OUT JSON->new->pretty->encode(\%data);
close OUT;
