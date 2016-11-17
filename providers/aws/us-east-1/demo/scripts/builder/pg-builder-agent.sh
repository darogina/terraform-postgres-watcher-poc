#!/bin/bash

usage() {
  cat <<EOF
Agent which will poll for Postgres commits on an SQS queue and build the corresponding artifacts

Usage:
  $0 <REPO_DIR> <LOGFILE> <QUEUE_URL> <POLLING_TIMEOUT>

<REPO_DIR>: Auto created if not already
<LOGFILE>: File which the run user has access to write to
<QUEUE_URL>: URL which points the the SQS queue
<POLLING_TIMEOUT>: Optional. Default to 5 seconds
EOF

  exit 1
}

REPO_DIR=$1
LOGFILE=$2
QUEUE_URL=$3

DEFAULT_POLLING_TIMEOUT=5
POLLING_TIMEOUT=${4:-$DEFAULT_POLLING_TIMEOUT}

if [ "x$REPO_DIR" == "x" ]; then
  echo
  echo "ERROR: Specify the repo dir as the first argument, e.g. /var/repo"
  echo
  usage
elif [ "x$LOGFILE" == "x"]; then
  echo
  echo "ERROR: Specify the log file as the third argument"
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
    #run_user=$1
    build_directory=$2
    commit=$3

    echo_log "BUILD_DIRECTORY = $build_directory"

    echo_log "Checking out commit $commit..."
    git fetch --all
    git checkout -f $commit

    echo_log "Building $commit..."
    #su - ${run_user} -c "mkdir -p $build_directory && cd $build_directory && ../configure && make"
    mkdir -p $build_directory && cd $build_directory && ../configure && make
    if [ $? -eq 0 ]; then
        echo_log "Postgres successful built. Commit: $commit"
        return 0
    else
        echo_log "Postgres build failure. Commit: $commit"
        return 1
    fi
}

test () {
    #run_user=$1
    build_directory=$2
    commit=$3

    echo_log "Running regression suite..."

    #su - ${run_user} -c "cd $build_directory && make check"
    cd $build_directory && make check
    if [ $? -eq 0 ]; then
        echo_log "Postgres regression suite passed. Commit: $commit"
        return 0
    else
        echo_log "Postgres regression suite failed. Commit: $commit"
        return 1
    fi
}

main () {
    # Create run user if not exist
    getent passwd postgres > /dev/null 2>&1 || adduser postgres

    # Setup the git repo clone
    mkdir -p $REPO_DIR
    cd $REPO_DIR
    if [ "$(ls -A $REPO_DIR)" ]; then
        echo_log "$REPO_DIR is not empty"
    else
        echo_log "Cloning git repo..."
        git clone --no-checkout https://github.com/postgres/postgres.git $REPO_DIR
    fi

    while true
    do
        message=$(aws sqs receive-message --queue-url $QUEUE_URL --max-number-of-messages 2 --visibility-timeout 10)

	if [ -z "$message" ]; then
            echo_log "No message received"
        else
            echo_log "Message Received \n $message"
            commit=$(echo ${message} | jq --raw-output '.Messages | .[0].Body' )
            receipt=$(echo ${message} | jq --raw-output '.Messages | .[0].ReceiptHandle' )
            echo_log $commit
            echo_log $receipt

            # Delete the message off the queue. Ideally create retry functionality
            aws sqs delete-message --queue-url $QUEUE_URL --receipt-handle $receipt

            # First: Build the commit
            build postgres "${REPO_DIR}/build_dir" $commit || continue

            # Second: Run regression suite
            test postgres "${REPO_DIR}/build_dir" $commit || continue

            # Third: Build RPMs

        fi

        echo_log "Sleeping for $POLLING_TIMEOUT seconds..."
        sleep $POLLING_TIMEOUT
    done
}

echo_log "Starting pg-builder-agent" >> $LOGFILE

main >> $LOGFILE 2>&1

# This should never be hit
exit 1
