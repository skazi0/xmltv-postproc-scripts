#!/usr/bin/perl -w
# remap peppa episode numbers in xmltv file
use strict;
use JSON;
use Data::Dumper;
use XML::Twig;
use File::Basename;
use utf8;

binmode STDOUT, ":utf8";
binmode STDIN, ":utf8";

my $script_dir = dirname(__FILE__);
open (IN, "<$script_dir/peppa.json");
local $/ = undef;
my $json = <IN>;
my $mapping = JSON->new->utf8->decode($json);
my @mappingkeys = sort { length $b <=> length $a } keys(%{$mapping});
close IN;

my $twig = XML::Twig->new(
    twig_roots => { 'programme' => \&process_programme },
    twig_print_outside_roots => 1
);
$twig->set_pretty_print('indented');
$twig->parsefile($ARGV[0]);

sub hashtitle {
    my $title = shift;
    $title = lc($title);
    $title =~ s/.*:\s*//; # strip series title
    $title =~ s/&/and/;
    $title =~ s/( |^)(a|the)( |$)//g;
    $title =~ s/[\.\s'’,]//g;
    # some pl/en wiki mismatches
    $title =~ s/ë/e/;
    $title =~ s/é/e/;
    $title =~ s/granda/grandpa/;
    return $title;
}

sub process_programme {
  #<programme start="20200305131500 +0100" stop="20200305133000 +0100" channel="TVP ABC">
  #  <title lang="pl">Świnka Peppa 4: Komputer Dziadka Świnki - odc. 5</title>
  #  <title lang="en">Peppa Pig: Grandpa Pig's Computer</title>
  #  <sub-title>serial animowany</sub-title>
  #  <desc lang="pl">Brytyjski serial animowany skierowany do maluchów w wieku przedszkolnym. Opowiada on o codziennym życiu i przygodach sym
  #  <date>2011</date>
  #  <category lang="pl">serial animowany</category>
  #  <icon src="https://media.teleman.pl/photos/470x265/Swinka-Peppa.jpeg" />
  #  <episode-num system="onscreen">5</episode-num>
  #  <rating system="PL">
  #    <value>b.o.</value>
  #  </rating>
  #</programme>
    my ($t, $prog) = @_;
    my $orgtitle = $prog->first_child('title[@lang="en"]');
    my $title = $prog->first_child('title[@lang="pl"]');
    # scan mapping only if generic pattern matches
    if ($orgtitle and $orgtitle->text =~ /Peppa Pig/ or
        $title and $title->text =~ /Świnka Peppa/) {
        my $hash = hashtitle($orgtitle ? $orgtitle->text : '<missing orgtitle>');
        for my $key (@mappingkeys) {
            if ($hash =~ $key) {
                # modify polish title
                my $epdata = $mapping->{$key};
                my $ser = $epdata->{'series'} != '1' ? " $epdata->{'series'}" : "";
                $title->set_text("Świnka Peppa$ser: $epdata->{'title'} - odc. $epdata->{'episode'}");
                $prog->first_child('episode-num')->set_text($epdata->{'episode'});
                last;
            }
        }
    }
    $prog->print;
}
