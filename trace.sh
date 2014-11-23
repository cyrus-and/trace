#!/usr/bin/env bash

readonly BASE_DIR="$(dirname $(readlink -e $0))"
readonly DEFAULT_GROUP="$BASE_DIR/trace.default.sh"

function usage {
    # dump the error message
    if [ -n "$1" ]; then
        echo "$1" >&2
        echo >&2
    fi

    echo >&2 "Usage:

    trace [<options>] -- run <program> [<arguments>]
    trace [<options>] -- attach <pid>
    trace [<options>] -- list

    <options> can be a combination of:

        -h                : show this message
        -d                : load the default group
        -g <group>        : group file to source
        -m <metric>       : metric to use
        -x <label> <code> : custom shell code to execute in which the variable
                            \$pid is defined to be the PID of the process being
                            traced; the first word of the argument is the label
                            and it will be shown as a column header
        -s <separator>    : column separator (defaults to tab)
        -i <interval>     : seconds between two consecutive measures (defaults to 1s)

    Options -g, -m and -x can (and should) be used multiple times. Options are
    evaluated in same the order as they appear.

    When using the 'run' command the program output is redirected to stderr so
    that measures are sent to stdout.

    Since the output is in a tabluar format it can be prettified with 'column -t'."

    # exit successfully if no errors are given
    [ -z "$1" ]; exit
}

function waitpid {
    local command="$1"
    local pid="$2"
    case "$command" in
        'run')
            # wait the child and return its status
            wait "$pid" &> /dev/null
            ;;
        'attach')
            # if the pid is not child of this shell then fallback to polling
            while kill -0 "$pid" &> /dev/null; do
                sleep 0.5
            done
            ;;
    esac
}

function tracer {
    local pid="$1"
    local separator="$2"
    local interval="$3"
    local label
    local metric
    local line
    # record time and write the first label
    local start="$(date +%s%3N)"
    echo -n 'ms'
    # write the other custom labels
    for label in "${labels[@]}"; do
        echo -n -e "$separator$label"
    done
    echo
    # tracer loop
    while [ -d "/proc/$pid/" ]; do
        # dump the time delta
        line="$(($(date +%s%3N) - $start))"
        # dump the next metric
        for metric in "${metrics[@]}"; do
            line="$line$(echo -n -e $separator)"
            line="$line$($metric | xargs echo -n)" # trim whitespaces
        done
        # print atomically the line; errors are ignored and sent on stderr
        echo "$line"
        sleep "$interval"
    done
}

function main() {
    local label
    local code

    local labels=()
    local metrics=()

    # parse common options
    OPTERR=0
    while getopts ':hdg:m:x:s:i:' arg; do
        case "$arg" in
            'h')
                usage
                ;;
            'd')
                source "$DEFAULT_GROUP"
                ;;
            'g')
                source "$OPTARG"
                ;;
            'm')
                # only accept metrics as functions defined in groups
                if [ "$(type -t m_$OPTARG)" = 'function' ]; then
                    labels+=("$OPTARG")
                    metrics+=("m_$OPTARG")
                else
                    echo "'$OPTARG' must be a metric function defined in some group."
                    exit 1
                fi
                ;;
            'x')
                read -r label code <<< "$OPTARG"
                if [ -n "$label" -a -n "$code" ]; then
                    labels+=("$label")
                    metrics+=("eval $code")
                else
                    usage "Invalid expression format '$OPTARG'; expecting '<label> <code>'."
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
    if [ "$#" = 0 ]; then
        usage "Missing command, either 'run' or 'attach'."
    fi

    # parse the command
    command="$1"
    shift
    case "$command" in
        'run')
            if [ "$#" = 0 ]; then
                usage 'Missing program to run.'
            fi
            # run the program in background redirecting stdout on stderr
            program="$1"; shift
            "$program" "$@" >&2 &
            program_pid="$!"
            ;;
        'attach')
            if [ "$#" = 0 ]; then
                usage 'Missing PID to attach.'
            fi
            # check the PID is actually used
            program_pid="$1"
            if ! [ -d "/proc/$program_pid/" ]; then
                echo "Process PID '$program_pid' is not running." >&2
                exit 1
            fi
            ;;
        'list')
            if [ "$#" != 0 ]; then
                usage "Invalid 'list' command syntax."
            fi
            # dump all the metrics available
            declare -F | awk 'substr($3,0,2) == "m_" {print substr($3,3)}'
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
    waitpid "$command" "$program_pid"
    status="$?"
    kill "$tracer_pid" &> /dev/null
    exit "$status"
}

main "$@"
