#!/bin/bash

usage() {
  cat <<EOF
Agent which will poll for Postgres commits on an SQS queue and build the corresponding artifacts

Usage:
  $0 <REPO_DIR> <QUEUE_URL> <POLLING_TIMEOUT>

<REPO_DIR>: Auto created if not already
<QUEUE_URL>: URL which points the the SQS queue
<POLLING_TIMEOUT>: Optional. Default to 5 seconds
EOF

  exit 1
}

LOGFILE=/var/log/pg-builder-agent.log

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

build () {
}

main () {
    # Setup the git repo clone
    mkdir -p $REPO_DIR
    cd $REPO_DIR
    if [ "$(ls -A $REPO_DIR)" ]; then
        echo_log "$REPO_DIR is not empty"
    else
        echo_log "Cloning git repo..."
        git clone --no-checkout https://github.com/darogina/testrepo.git .    
    fi
    
    while true
    do
        message=$(aws sqs receive-message --queue-url $QUEUE_URL --max-number-of-messages 1 --visibility-timeout 600)

	if [ -z "$message" ]; then
            echo_log "No message received"
        else
            echo_log "Message Received \n $message"
        fi
    
        echo_log "Sleeping for $POLLING_TIMEOUT seconds..."
        sleep $POLLING_TIMEOUT
    done
}

echo_log "Starting pg-builder-agent" >> $LOGFILE

main >> $LOGFILE 2>&1

# This should never be hit
exit 1
