#!/usr/bin/env bash

set -euo pipefail

src='../thesis/doc/imgs'
[[ ! -d "$src" ]] && echo "source folder is missing: $src" && exit 1

[[ ! -d imgs ]] && mkdir -v imgs

rsync --verbose ${src}/*.png imgs/

for f in ${src}/*.pdf; do
    convert -verbose -density 300 $f imgs/$(basename ${f%.*}).png;
done
