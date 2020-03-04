#!/usr/bin/perl -w
# generate peppa.json out of wikipedia tables
use strict;
use Data::Dumper;
use JSON;

my %data;

sub hashtitle {
    my $title = shift;
    $title = lc($title);
    $title =~ s/( |^)(a|the)( |$)//g;
    $title =~ s/[\.\s'’]//g;
    # some pl/en wiki mismatches
    $title =~ s/ë/e/;
    $title =~ s/é/e/;
    $title =~ s/rid$/ride/;
    $title =~ s/granda/grandpa/;
    $title =~ s/grampyrabbitslighthouse/lighthouse/;
    return $title;
}

# load english titles and episodes
my $series;
my $ep;
my $title;
my %eps;
open(I, '<peppa_en.md');
while (my $line = <I>) {
    chomp $line;
    if ($line =~ /\}\}/) {
        if ($title and $ep and $series) {
            $eps{hashtitle($title)} = {'title' => $title, 'series' => $series, 'episode' => $ep};
        }
        $ep = $title = undef;
        next;
    }
    if ($line =~ /===Series (\d).*===/) {
        $series = $1;
        $ep = undef;
        next;
    }
    if ($line =~ /===Specials.*===/) {
        $series = undef;
        next;
    }
    if ($line =~ /EpisodeNumber2\s*=\s*(\d+)/) {
        $ep = $1;
        next;
    }
    if ($line =~ /Title\s*=\s*(.+)/) {
        $title = $1;
        next;
    }
}
close I;

# load polish titles and find episodes for them in english titles
open(I, '<peppa_pl.md');
my @titles;
my $inbody = 0;
while (my $line = <I>) {
    chomp $line;
    if ($line =~ /^\|-/) {
        # not empty
        if (scalar @titles) {
            my $orgtitle = pop @titles;
            for my $title (@titles) {
                my $epsdata = $eps{hashtitle($orgtitle)};
                $data{hashtitle($epsdata->{'title'})} = $data{hashtitle($orgtitle)} = { 'orgtitle' => $orgtitle, 'title' => $title, 'series' => $epsdata->{'series'}, 'episode' => $epsdata->{'episode'} };
                print Dumper($data{$orgtitle}) if (!$data{hashtitle($orgtitle)}->{'series'});
            }
        }
        @titles = ();
        next;
    }

    next if ($line =~ /bgcolor|^\|\s*$/);

    if ($line =~ /tytuł/) {
        $inbody = 1;
        next;
    }

    $line =~ s/.*\|\s*|''|<.*|\s+$//g;
    if ($inbody) {
        push @titles, $line;
    }
}
close I;

# write mapping to json
open (OUT, ">peppa.json");
print OUT JSON->new->pretty->encode(\%data);
close OUT;
