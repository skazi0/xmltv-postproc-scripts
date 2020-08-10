#!/bin/sh
$HOME/.wg++/run.sh
$HOME/postproc-scripts/peppa/remap_peppa_episodes.pl $HOME/public/epg.xml > $HOME/public/epg-post1.xml
$HOME/postproc-scripts/bossbaby/remap_episodes.pl $HOME/public/epg-post1.xml > $HOME/public/epg-post.xml
