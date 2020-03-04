#!/bin/sh
$HOME/.wg++/run.sh
$HOME/postproc-scripts/peppa/remap_peppa_episodes.pl $HOME/public/epg.xml > $HOME/public/epg-post.xml
