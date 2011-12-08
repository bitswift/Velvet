#!/bin/sh
#
# Run this script from the root of the repository to generate Appledoc
# documentation. Any arguments on the command line are passed through without
# modification.

appledoc -o Documentation --explicit-crossref --no-repeat-first-par --no-search-undocumented-doc --project-name "$1" --project-company "Emerald Lark" "$2"
exit 0
