#!/bin/bash

usage() {
  cat <<EOF
Agent which will poll for Postgres commits on an SQS queue and build the corresponding artifacts

Usage:
  $0 <REPO_DIR> <RPM_REPO_DIR> <LOGFILE> <QUEUE_URL> <POLLING_TIMEOUT>

<REPO_DIR>: Auto created if not already
<RPM_REPO_DIR>: Auto created if not already
<LOGFILE>: File which the run user has access to write to
<QUEUE_URL>: URL which points the the SQS queue
<POLLING_TIMEOUT>: Optional. Default to 5 seconds
EOF

  exit 1
}

REPO_DIR=$1
RPM_REPO_DIR=$2
LOGFILE=$3
QUEUE_URL=$4

DEFAULT_POLLING_TIMEOUT=5
POLLING_TIMEOUT=${5:-$DEFAULT_POLLING_TIMEOUT}

if [ "x$REPO_DIR" == "x" ]; then
  echo
  echo "ERROR: Specify the repo dir as the first argument, e.g. /var/repo"
  echo
  usage
elif [ "x$RPM_REPO_DIR" == "x" ]; then
  echo
  echo "ERROR: Specify the rpm repo dir as the second argument, e.g. /var/rpm"
  echo
  usage
elif [ "x$LOGFILE" == "x" ]; then
  echo
  echo "ERROR: Specify the log file as the third argument"
  echo
  usage
elif [ "x$QUEUE_URL" == "x" ]; then
  echo
  echo "ERROR: Specify the SQS Queue URL as the fourth argument"
  echo
  usage
fi

echo_log () {
    TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
    echo "$TIMESTAMP $1"
}

build () {
    build_directory=$1
    commit=$2

    echo_log "BUILD_DIRECTORY = $build_directory"

    echo_log "Checking out commit $commit..."
    git fetch --all
    git checkout -f $commit

    echo_log "Building $commit..."
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
    build_directory=$1
    commit=$2

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

create_rpm () {
    echo_log "Creating RPMs..."

    # Make sure the rpm git repo is up to date
    cd $RPM_REPO_DIR
    git checkout -f master && git pull

    cd rpm/redhat/9.6/postgresql/EL-7

    # Create a tarball of the source and move it to the rpm spec repo.
    # The tarball creation is not necessary if skipping the pgrpm repo Makefile prep target
    mkdir -p postgresql-9.6.1 && cp -R $REPO_DIR/* postgresql-9.6.1/
    tar -cjSf postgresql-9.6.1.tar.bz2 -C . ./postgresql-9.6.1

    make rpm

    if [ "$(ls -A ./x86_64)" ]; then
        echo_log "Postgres RPMs successfully created"
        return 0
    else
        echo_log "Postgres RPM creation failed"
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
        git clone https://github.com/postgres/postgres.git $REPO_DIR
    fi

    # Setup the git rpm repo clone
    mkdir -p $RPM_REPO_DIR
    cd $RPM_REPO_DIR
    if [ "$(ls -A $RPM_REPO_DIR)" ]; then
        echo_log "$RPM_REPO_DIR is not empty"
    else
        echo_log "Cloning git rpm repo..."
        git clone https://git.postgresql.org/git/pgrpms.git --branch master --single-branch $RPM_REPO_DIR
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
            build "${REPO_DIR}/build_dir" $commit || continue

            # Second: Run regression suite
            test "${REPO_DIR}/build_dir" $commit || continue

            # Third: Build RPMs
            create_rpm $RPM_REPO_DIR || continue

            # Do something with the RPMs
        fi

        echo_log "Sleeping for $POLLING_TIMEOUT seconds..."
        sleep $POLLING_TIMEOUT
    done
}

echo_log "Starting pg-builder-agent" >> $LOGFILE

main >> $LOGFILE 2>&1

# This should never be hit
exit 1

