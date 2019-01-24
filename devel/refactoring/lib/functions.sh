#!/bin/bash
set -e

function parse-diff-filter-args() {
    commit=$1
    if [[ -z $commit && -t 0 ]]; then
        echo "usage: $(basename $0) commitish"
        echo "       git diff ... | $(basename $0)"
        exit 1
    elif [[ -n $commit ]]; then
        diff="git show -p $commit"
    elif [[ ! -t 0 ]]; then
        diff="cat"
    fi
}

function echo-header() {
    BOLD="\033[1m"
    RESET="\033[0m"
    echo -e "$BOLD# $@$RESET"
}

function setup-pager() {
    if [ -t 1 ]; then
        AUTOPAGER=${PAGER:-less -SRFXi}
    else
        AUTOPAGER=cat
    fi
}

function if-pager() {
    if [[ $AUTOPAGER != cat ]]; then
        echo "$@"
    fi
}

function maybe-pager() {
    $AUTOPAGER
}

# These are a portable grep -oP and grep -vP for systems without GNU grep.
#   God help them.
#
# The export pattern and %ENV shenanigans are intentional.  Unlike
# interpolating the pattern into the Perl snippet, the current solution avoids
# the need to pick m// delimiters that don't interfere with the arbitrary
# pattern we're passed (or alternatively, the need to escape said delimiters
# correctly in the pattern).  While passing in the pattern as the first
# argument would also do the trick, that breaks -n's behaviour (via <>) of
# choosing stdin or the argument list since it always sees arguments.  Yes, we
# could not use -n and instead write the while loop ourselves, but I think it's
# no better on technical merits and find this more aesthetically pleasing.
#   -trs, 21 Dec 2017
#
function extract-matches() {
    local pattern="$1"
    export pattern
    shift
    perl -nE 'say $& if $_ =~ $ENV{pattern}' "$@"
}

function ignore-matching() {
    local pattern="$1"
    export pattern
    shift
    perl -nE 'print unless $_ =~ $ENV{pattern}' "$@"
}
