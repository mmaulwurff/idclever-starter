#!/bin/bash

set -e

name=idclever-starter

rm -f $name.pk3

git log --date=short --pretty=format:"-%d %ad %s%n" | \
    grep -v "^$" | \
    sed "s/HEAD -> master, //" | \
    sed "s/, origin\/master//" | \
    sed "s/ (HEAD -> master)//" | \
    sed "s/ (origin\/master)//"  |\
    sed "s/- (tag: \(v\?[0-9.]*\))/\n\1\n-/" \
    > changelog.txt

zip $name.pk3 \
    filter/*/*.enu \
    zscript/*.zs \
    *.txt \
    *.zs \
    *.md \
    language.enu

cp $name.pk3 $name-$(git describe --abbrev=0 --tags).pk3

gzdoom -file $name.pk3 "$@"
