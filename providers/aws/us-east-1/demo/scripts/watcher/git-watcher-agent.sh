#!/bin/bash

usage() {
  cat <<EOF
Agent which will watch for Postgres commits and send a message to SQS upon new commits

Usage:
  $0 <REPO_DIR> <QUEUE_URL> <POLLING_TIMEOUT>

<REPO_DIR>: Auto created if not already
<QUEUE_URL>: URL which points the the SQS queue
<POLLING_TIMEOUT>: Optional. Default to 5 seconds
EOF

  exit 1
}

LOGFILE=/var/log/git-watcher-agent.log

REPO_DIR=$1
QUEUE_URL=$2
DEFAULT_POLLING_TIMEOUT=5
POLLING_TIMEOUT=${3:-$DEFAULT_POLLING_TIMEOUT}

if [ "x$REPO_DIR" == "x" ]; then
  echo
  echo "ERROR: Specify the repo dir as the first argument, e.g. /var/repo"
  echo
  usage
elif [ "x$QUEUE_URL" == "x" ]; then
  echo
  echo "ERROR: Specify the SQS Queue URL as the second argument"
  echo
  usage
fi

echo_log () {
    TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
    echo "$TIMESTAMP $1" 
}

handle_commits () {
    COMMITS=$1
    
    # Return if commits is not an array
    declare -p ${COMMITS} 2> /dev/null | grep 'declare \-a' >/dev/null && return 0

    # Loop in reverse order over the commits
    for ((i=${#COMMITS[@]}-1; i>=0; i--)); do
        echo_log "New Commit: ${COMMITS[$i]}"
        
        # Add new message to SQS queue
        aws sqs send-message --queue-url $QUEUE_URL --message-body "${COMMITS[$i]}"
    done
}

main () {
    # Setup the git repo clone
    mkdir -p $REPO_DIR
    cd $REPO_DIR
    if [ "$(ls -A $REPO_DIR)" ]; then
        echo_log "$REPO_DIR is not empty"
    else
        echo_log "Cloning git repo..."
        git clone --mirror https://github.com/darogina/testrepo.git .    
    fi
    
    while true
    do
        echo_log 'Starting execution'
        # Get current HEAD hash
        CURRENT_HEAD=$(git rev-parse HEAD)
    
        # do a fetch and get the new HEAD
        git fetch --all
        UPDATED_HEAD=$(git rev-parse HEAD)
    
        # Add all new commits to an array
        COMMITS=($(git log $CURRENT_HEAD..$UPDATED_HEAD --pretty=oneline | awk '{print $1}'))
    
        # Shortcircuit if there are no new commits
        if [ ${#COMMITS[@]} -eq 0 ]; then
            echo_log 'No new commits'
        else
            echo_log 'New commits found'
            handle_commits $COMMITS
        fi
    
        echo_log "Sleeping for $POLLING_TIMEOUT seconds..."
        sleep $POLLING_TIMEOUT
    done
}

echo_log "Starting git-watcher-agent" >> $LOGFILE

main >> $LOGFILE 2>&1

# This should never be hit
exit 1
