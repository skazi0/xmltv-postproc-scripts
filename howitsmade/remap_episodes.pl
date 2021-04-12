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
#  <programme start="20210413092000 +0200" stop="20210413095000 +0200" channel="Metro TV">
#    <title lang="pl">Jak to jest zrobione?</title>
#    <title lang="en">How It's Made 32: Compression &amp; Extension Springs, Micro Drill Bits, Skiffs, Painted Glass Backsplashers</title>
#    <desc lang="pl">Widzowie dowiedzą się, w jaki sposób powstają sprężyny przemysłowe, mikrowiertła, łódki motorowe i ścienne panele szklane. Przedmioty codz
#    <date>2019</date>
#    <category lang="pl">serial dokumentalny</category>
#    <episode-num system="onscreen">22</episode-num>
#    <rating system="PL">
#      <value>12</value>
#    </rating>
#  </programme>
    my ($t, $prog) = @_;
    my $orgtitle = $prog->first_child('title[@lang="en"]');
    my $title = $prog->first_child('title[@lang="pl"]');
    # scan mapping only if generic pattern matches
    if ($title->text =~ /Jak to jest zrobione/) {
        for my $key (@mappingkeys) {
            my $title_a = $mapping->{$key}->{'title_a'};
            if ($orgtitle->text =~ /:\s*$title_a,/i) {
                # modify episode title and number
                my $epdata = $mapping->{$key};
#                $title->set_text("Jak to jest zrobione?: $epdata->{'title_a'}, $epdata->{'title_b'}, $epdata->{'title_c'}, $epdata->{'title_d'}");
                $prog->first_child('episode-num')->set_text($epdata->{'episode'});
                last;
            }
        }
    }
    $prog->print;
}
