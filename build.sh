#!/bin/bash

name=idclever-starter

rm -f $name.pk3 \
&& \
git log --pretty=format:"-%d %ai %s%n" > changelog.txt \
&& \
zip $name.pk3 \
    *.txt \
    *.md \
&& \
cp $name.pk3 $name-$(git describe --abbrev=0 --tags).pk3 \
&& \
gzdoom -glversion 3 -file \
       $name.pk3 \
       ~/Programs/Games/wads/maps/DOOMTEST.wad \
       "$1" "$2" \
       +map test \
       -nomonsters
