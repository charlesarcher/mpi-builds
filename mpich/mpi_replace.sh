#!/bin/sh

git grep $1 | cut -d: -f1 | sort | uniq | xargs perl -p -i -e "s/\Q$1\E/$2/g"
