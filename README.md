trace
=====

Start or attach to a process and monitor a customizable set of parameters (CPU,
I/O, etc.). The generated output uses a easily parsable tabular format and is
ready to use out of the box with tools like [R][r].

Examples
--------

Attach to a running instance of `cp` to monitor the amount of bytes
read/written:

    trace -d -mread_b -mwrite_b -- attach $(pidof cp)

Trace the evolution of the memory allocations of an executable and the overall
swap usage:

    trace -d -mres_mem_kb -mswap_mem_kb -mused_swap_kb -mtotal_swap_kb -- run ./something

Installation
------------

    wget -qO- https://raw.githubusercontent.com/cyrus-and/trace/master/install.sh | bash

Or manually put `trace.sh` and `trace.default.sh` wherever you want and symlink
the former to just `trace` in one of your `$PATH` directories.

Or just run it from where it is with `./trace.sh`. The only requirement is that
if you want to use the default metrics group, the file `trace.default.sh` must
be in the same directory as `trace.sh`.

(Same apply for `uninstall.sh`).

Usage
-----

The full usage message is shown with the `-h` option.

    trace [<options>] -- run <program> [<arguments>]
    trace [<options>] -- attach <pid>

    <options> can be a combination of:

        -h                : show this message
        -d                : load the default group
        -g <group>        : group file to source
        -m <metric>       : metric to use
        -x <label>:<code> : custom shell code to execute in which the variable
                            \$pid is defined to be the PID of the process being
                            traced; the given label will be shown as a column
                            header
        -s <separator>    : column separator (defaults to tab)
        -i <interval>     : seconds between two consecutive measures (defaults to 1s)

For a list of available metrics in the default group take a look at the
[source code][default].

### Output

The output produced is tab-separated values by default, though the field
separator can be specified with the `-s` option. This format is particular
suitable to be parsed by tools like [R][r], for example using the `read.table`
function:

```r
trace <- read.table('trace.tsv',header=T)
```

For human consumption it is also possible to pipe the output through the `column
-t` command to determine the proper length of the columns and thus get a
prettified version of the table.

Note that when using the 'run' command the program output is redirected to
stderr so that measures are sent to stdout.

### Groups

Groups are shell files that contains user defined functions (metrics) that can
be loaded only when needed via the `-g` option. Most of the time the default
group will be just enough hence there is a shortcut option `-d` that takes care
of loading it.

In case you need to write your own custom group file you can use the
[default group][default] as a base line. Of course you should avoid naming
conflicts when dealing with multiple files.

### Metrics

Metrics are lightweight shell functions that dump precisely one value for the
PID being traced in the current time instance, for example the CPU load. Metrics
are specified with the `-m` option and each one eventually corresponds to a
column in the output. `-m` must specify the name of the function to use and such
function must be present in a previously included group file via the `-g` or
`-d` options. The column label is the function name. For example:

    trace -d -mread_b -- run dd if=my-file of=/dev/null

There is another kind of metrics (`-x` option) that allows to quickly specify a
custom column without having to provide a whole custom group file. The accepted
format is `<label>:<code>`. In this case the column label is the one
provided. For example:

    trace -x 'file_count:ls | wc -l' -- run ./something

[r]: http://www.r-project.org/
[default]: trace.default.sh
