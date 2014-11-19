#!/usr/bin/env bash

DEFAULT_GROUP='./trace.default.sh'

labels=()
metrics=()

function usage {
    echo >&2 "$1

Usage:

    trace [<options>] -- run <program> [<arguments>]
    trace [<options>] -- attach <pid>

    <options> can be a combination of:

        -d                : load the default group
        -g <group>        : group file to source
        -m <metric>       : metric to use
        -x <label>:<code> : custom shell code to execute in which the variable
                            \$pid is defined to be the PID of the process being
                            traced; the given label will be shown as column
                            header
        -s <separator>    : column separator (defaults to tab)
        -i <interval>     : seconds between two consecutive measures (defaults to 1s)

    Options -g, -m and -x can (and should) be used multiple times. Options are
    evaluated in same the order as they appear.

    When using the 'run' command the program output is redirected to stderr so
    that measures are sent to stdout.

    Since the output is in a tabluar format it can be prettified with 'column -t'."
    exit 1
}

function waitpid {
    # if the pid is not child of this shell then fallback to polling
    if ! wait "$1" &> /dev/null; then
        while kill -0 "$1" &> /dev/null; do
            sleep 0.5
        done
    fi
}

function tracer {
    local pid="$1"
    local separator="$2"
    local interval="$3"
    # record time and write the first label
    local start="$(date +%s)"
    echo -n 'seconds'
    # write the other custom labels
    for label in "${labels[@]}"; do
        echo -n -e "$separator$label"
    done
    echo
    # tracer loop
    while [ -d "/proc/$pid/" ]; do
        # dump the time delta
        echo -n "$(($(date +%s) - $start))"
        # dump the next metric
        for metric in "${metrics[@]}"; do
            echo -n -e "$separator"
            $metric | xargs echo -n # trim whitespaces
        done
        echo
        sleep "$interval"
    done
}

# parse common options
OPTERR=0
while getopts ':dg:m:x:s:i:' arg; do
    case "$arg" in
        'd')
            source "$DEFAULT_GROUP"
            ;;
        'g')
            source "$OPTARG"
            ;;
        'm')
            # only accept metrics as functions defined in groups
            if [ $(type -t "$OPTARG") = 'function' ]; then
                labels+=("$OPTARG")
                metrics+=("$OPTARG")
            else
                echo "'$OPTARG' must be a function or an alias defined in some group."
                exit 1
            fi
            ;;
        'x')
            IFS=':' read label code <<< "$OPTARG"
            if [ -n "$label" -a -n "$code" ]; then
                labels+=("$label")
                metrics+=("eval $code")
            else
                usage "Invalid expression format '$OPTARG'; expecting '<label>:<code>'."
            fi
            ;;
        's')
            separator="$OPTARG"
            ;;
        'i')
            interval="$OPTARG"
            ;;
        ':')
            usage "The argument is needed for option '$OPTARG'."
            ;;
        '?')
            usage "Unknown option '$OPTARG'."
            ;;
    esac
done

# consume the parsed options
shift $((OPTIND-1))

# check arguments count
if [ "$#" -lt 2 ]; then
    usage "Missing command, either 'run' or 'attach'."
fi

# parse the command
command="$1"
shift
case "$command" in
    'run')
        # run the program in background redirecting stdout on stderr
        program="$1"; shift
        "$program" "$@" >&2 &
        program_pid="$!"
        ;;
    'attach')
        program_pid="$1"
        ;;
    *)
        usage "Invalid command '$command'."
        ;;
esac

# kill all the children on ^C (SIGPIPE avoid Bash process control feedback)
trap 'kill -PIPE 0' SIGINT

# start data collector
tracer "$program_pid" "${separator:-\t}" "${interval:-1}" &
tracer_pid="$!"

# wait program termination and do cleanup
waitpid "$program_pid"
status="$?"
kill "$tracer_pid" &> /dev/null
exit "$status"
