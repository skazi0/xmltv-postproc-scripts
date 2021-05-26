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

if (open(I, '<episodes.json')) {
    local $/ = undef;
    my $json = <I>;
    close I;
    %data = %{JSON->new->decode($json)};
}

open(I, '<season15.md');
my @titles;
my $epnum;
my $sepnum;
while (my $line = <I>) {
    chomp $line;
    if ($line =~ /^(==|!|{)/) {
        next;
    }
    if ($line =~ /^\|-|^\|}/) {
        # not empty
        if (scalar @titles and $epnum) {
            my ($title_a, $title_b, $title_c, $title_d) = @titles;
            $data{hashtitle($title_a)} = { 'title_a' => $title_a, 'title_b' => $title_b, 'title_c' => $title_c, 'title_d' => $title_d, 'episode' => $epnum, 'series_episode' => $sepnum };
        }
        @titles = ();
        $epnum = $sepnum = undef;
        next;
    }

    $line =~ s/^\|\s*|\s+$|\[\[[^\|\]]+\|//g;
    $line =~ s/\[\[|\]]//g;

    my @parts = split(/\s*\|\|\s*/, $line);

    if (!$sepnum) {
        $sepnum = shift @parts;
        $sepnum =~ s/^\|\s+|\s+$//g;
    }

    if (!$epnum) {
        $epnum = int(shift @parts);
    }

    push @titles, @parts;
}
close I;

# write mapping to json
open (OUT, ">episodes.json");
print OUT JSON->new->pretty->encode(\%data);
close OUT;
