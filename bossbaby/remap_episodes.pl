#!/usr/bin/perl -w
# remap episode numbers in xmltv file
use strict;
use JSON;
use Data::Dumper;
use XML::Twig;
use File::Basename;
use utf8;

binmode STDOUT, ":utf8";
binmode STDIN, ":utf8";

my $script_dir = dirname(__FILE__);
open (IN, "<$script_dir/episodes.json");
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
    $title =~ s/( |^)(a|the)( |$)//g;
    $title =~ s/[\.\s'’!,:&-]//g;
    return $title;
}

sub process_programme {
#  <programme channel="TV Puls 2" start="20200818171500 +0200" stop="20200818174500 +0200">
#    <title lang="pl">Dzieciak rządzi: Znowu w grze - odc. 11</title>
#    <title lang="en">Boss Baby: Back in Business: Cat Cop!</title>
#    <sub-title>serial animowany</sub-title>
#    <desc lang="pl">Rodziny dzieci opuszczają miasto. Szef Bobas razem z bratem Timem próbuje odkryć, co jest przyczyną tej decyzji. Szef Bobas zaprasza do firmy starszego brata - Tima. Chce go nauczyć, jak robi się prawdziwy biznes. Przy okazji stara się osiągnąć to, co wydaje się prawie niemożliwe: równowagę pomiędzy życiem zawodowym a prywatnym nowoczesnego dziecka-przedsiębiorcy</desc>
#    <date>2017</date>
#    <category lang="pl">serial animowany</category>
#    <episode-num system="onscreen">11</episode-num>
#    <rating system="PL">
#      <value>7</value>
#    </rating>
#  </programme>
    my ($t, $prog) = @_;
    my $orgtitle = $prog->first_child('title[@lang="en"]');
    my $title = $prog->first_child('title[@lang="pl"]');
    # scan mapping only if generic pattern matches
    if ($orgtitle and $orgtitle->text =~ /Boss Baby: / or
        $title and $title->text =~ /Dzieciak rządzi: /) {
        my $hash = hashtitle($orgtitle->text);
        for my $key (@mappingkeys) {
            if ($hash =~ $key) {
                # modify polish title
                my $epdata = $mapping->{$key};
                $title->set_text("Dzieciak rządzi: Znowu w grze: $epdata->{'title'} - odc. $epdata->{'episode'}");
#                $prog->first_child('episode-num')->set_text($epdata->{'episode'});
                last;
            }
        }
    }
    $prog->print;
}
