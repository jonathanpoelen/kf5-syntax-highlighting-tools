#!/bin/zsh
tmp=${TMPDIR:-/tmp}/$$-reduce-xml.swap
for f in $@ ; do
  tr -d '\n' <$f > $tmp ; mv $tmp $f
done
sed -E 's/<!--([^-]|[^-][^-]|[^-][^-][^>])*-->//g;s/\s+</</g;' -i -- $@
# 's/\s+"/ "/g;s/"\s+/" /g'
