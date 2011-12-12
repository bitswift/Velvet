#!/bin/sh
#
# Run this script from the root of the repository to generate Appledoc
# documentation. Any arguments on the command line are passed through without
# modification.

PROJECT_NAME=`ls | grep -m 1 *.xc* | awk -F. '{ print $1 }'`

appledoc -o Documentation --explicit-crossref --no-repeat-first-par --no-search-undocumented-doc --project-company "Emerald Lark" --project-name "$PROJECT_NAME" "$@"
exit 0
