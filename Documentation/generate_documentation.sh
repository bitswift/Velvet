#!/bin/sh
#
# Run this script from the root of the repository to generate Appledoc
# documentation. Any arguments on the command line are passed through without
# modification.

appledoc -o Documentation --explicit-crossref --no-repeat-first-par --no-search-undocumented-doc --project-name Velvet --project-company "Emerald Lark" "$@" Framework/Velvet/Velvet

# AppleDoc's exit status is 1 on success
if [ "$?" -ne 1 ]
then
    exit 1
else
    exit 0
fi
