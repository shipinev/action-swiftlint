#!/bin/bash

sh -c "git config --global --add safe.directory $PWD"

# convert swiftlint's output into GitHub Actions Logging commands
# https://help.github.com/en/github/automating-your-workflow-with-github-actions/development-tools-for-github-actions#logging-commands

function stripPWD() {
    if ! ${WORKING_DIRECTORY+false};
    then
        cd - > /dev/null
    fi
    sed -E "s/$(pwd|sed 's/\//\\\//g')\///"
}

function convertToGitHubActionsLoggingCommands() {
    sed -E 's/^(.*):([0-9]+):([0-9]+): (warning|error|[^:]+): (.*)/::\4 file=\1,line=\2,col=\3::\5/'
}

if ! ${WORKING_DIRECTORY+false};
then
	cd ${WORKING_DIRECTORY}
fi

if ! ${DIFF_BASE+false};
then
	echo $(git log)
	changedFiles=$(git --no-pager diff --name-only origin/$DIFF_BASE..HEAD -- '*.swift')

	if [ -z "$changedFiles" ]
	then
		echo "No Swift file changed"
		exit
	fi
fi

set -o pipefail && swiftlint "$@" -- $changedFiles | stripPWD | convertToGitHubActionsLoggingCommands
