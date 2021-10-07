#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

mkdir -p "$script_dir/../build-output"

figlet Functions
cd functions
yarn

zip -r "$script_dir/../build-output/functions.zip" . -x local.*


if [[ -z $IS_CI ]]; then
    echo "IS_CI not set, skipping git status check"
    exit 0
fi
figlet git status
cd "$script_dir/.."
if [[ -n $(git status --short) ]]; then
    echo "*** There are unexpected changes in the working directory (see git status output below)"
    echo "*** Ensure you have run scripts/build-local.sh"
    git status
    exit 1
fi
