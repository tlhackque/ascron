# ascron - Run cron jobs interactively

When you are developing something to run under `cron`, or just in the course of normal events, things go wrong.

When you want to re-run or test changes, editing the `crontab`, waiting for `crond` to notice, and for the clock to tick over is at least annoying, and often frustrating.  But trying to run the job interactively often runs into trouble, because the environment under `crond` differs greatly from a typical interactive session.

Some of the differences include:

 - The shell (by default `/bin/sh`
 - The PATH (by default very restricted)
 - How output is captured and delivered
 - The defined environment variables
 - Standard input
 - Running as another user

`ascron` lets you run a `cron` job **on your terminal** directly from an installed `crontab`, in exactly the same environment as when `cron` runs it.  It enables you to run from an uninstalled `crontab`, so you can have confidence that it will work the first time.  It also enables you to run an arbitrary command _as if_ it was installed in a specific `crontab` for faster turn-around.  All in all, when you finally install your job, there should be no surprises.

`ascron` also assists in finding `cron` jobs and determining the time at which they'll next run.

Brief help (--man for detail):

# NAME

ascron - Run cron jobs from a terminal

# SYNOPSIS

    ascron   command | job-regexp
              --format  --job     --list    --mail-action --locale --match
              --system  --table   --user    --debug=file  --tz      --notz
              --detach  --pidfile --find
              --help    --man     --version

# DESCRIPTION

_ascron_ runs a command in the environment it would have if run by (Vixie) _crond_, without
the difficulties of editing a _crontab_ and waiting for _crond_ to notice it.

_ascron_ can select jobs from any installed _crontab_ (user or system), from an uninstalled
_crontab_, or can run a job defined on the command line.

The Vixie cron extensions are supported in _crontabs_: named weekdays and months, ranges, step
counts, and @abbreviations (such as @daily).

_ascron_ sets up the environment using the same process as _crond_ does when reading _crontab_s.

_ascron_ obeys the same enviroment variables as _crond_ for determining the SHELL, PATH, and output
disposition.

Additionally, _ascron_ allows the job's output to be sent to stdout, e-mail, or discarded,.  E-mail
is sent exactly as _crond_ would, obeying the crontab's environment variables.

When running jobs, _ascron_ will (if run as root) run them as the appropriate user, setting the job's
**UID**, **GID**, and groups as specified.

See **EXAMPLES** for how these interact.

# OPTIONS

The following options are used to select the _crontab_(s) searched, and the function performed or job to be run.

**system** _crontabs_ include the user under which a job runs.  These include `/etc/crontab` and `/etc/cron.d/*`.
**user** _crontabs_ do not include the user.  The user is implied by the Icrontab>'s location or by the **--format** option.  The user may also be specified by the **--user** option, which also implies a default table.

Options contained in `~/.ascron` will be applied before any specified on the command line.  The **--no** forms of options may be useful on the command line to override `~/.ascron`.

- **-d** **--debug**=`file` **--nodebug**

    Writes a detailed log of processing events to `file`.  `file` may be '-' for `stderr`.

    While intended for debugging _ascron_, some of the detail may be helpful for understanding how _cron_ processes a job.

- **-D** **--\[no\]detach** **--\[no\]daemon**

    _ascron_ daemonizes itself before running the job.  This frees your terminal when executing long-running jobs, and is how _crond_ runs.

    This does not affect **--debug** output if `stderr` is specified.

    Ues **--pidfile** if you want to capture the PID of the daemon.

    Consider placing **--detach** in your `.ascron` if long-running jobs are the norm.

- **-f** **--format**=_automatic|system_|_user_

    Specifies the format of the _crontab_(s) read by the command.

    _automatic_, the default, determines the format using **--table**, **--user**, and/or **--job**.

- **-j** **--job**

    Specifies the job(s) to be located in the _crontab_(s).  The command arguments are unanchored regular expressions that match each _crontab_ command.  If more than one argument is specified, they are combined with _or_; that is, a command is selected if any of the arguments matches.  By default, the first matching command will be used, but **--match** can specify a subsequent match.

    If **--job** is not specified or **--nojob**/**--command**/**-c** is specified, the command is specified by the command line arguments.

- **-l** **--\[no\]list**

    With **--job**, lists all matching jobs in the specified table(s) (and does not execute any).  Useful with multiple matches to determine a value of **--match** that will select the desired job.

    **--list** can also be used to determine the next time at which  _crond_ will execute matching jobs.

- **-F** **--\[no\]find**

    Searches all installed tables (system and user) for matching jobs (and does not execute any).  If **--user** is not specified, searches all users' tables.  **--find** does not match **--table** or **--format**.  Useful when you know a job is running under _cron_, but don't know where to find it.

- **-M** **--mail-action**=_discard_|_display_|_send_

    Output on `stdout` or `stderr` from _cron_ jobs is (usually) e-mailed; the destination, source, subject, and format are controlled by environment variables set in the _crontab_.

    By default, _ascron_ faithfully emulates this behavior -- which can be inconvenient for debugging jobs.  **--mail-action** can override the default action so that the mail message is displayed (on `stdout`) or discarded.

- **-p** **--pidfile**=`file` **--nopidfile**

    Write the PID of the job to `file` as _j:&lt;pid_>.

    When daemonizing, also write the PID of the daemon to `file` as _d:&lt;pid_>.  The order of the PIDs is unpredictable.

- **-t** **--table**=`file` **--notable**

    Selects the _crontab_ file used to extract environment variables, and (with **--job**) the command.

    Note that without **--job**, the job defined on the command line is processed as if it is located at the end of the _crontab_.  Thus, if an environment variable is re-defined in a _crontab_, the last definition is used.

    If not specified or defaulted, all system tables are read.

- **-u** **--user**=_name_ **--nouser**

    Specifies the username to be matched when locating a job or table; under which the job executes.

    If **--table** is not specified, **--user** implies the user's private table.

    If a username is required, but not determined implicitly or by **--user**, the username is obtained from the opertor's (effective) _UID_.

- **-m** **--match**=_n_

    Specifies that the _n_th matching job is to be used.  The first (and default) match is numbered 1.

- **-z** **--tz**=i&lt;zone>  **-Z** **--notz**

    _crond_ implementations vary considerably in whether jobs have **TZ** (the timezone) in their environment, and if they do, where it comes from and what it contains.

    _ascron_ attempts to set **TZ** from its environment, or failing that from several system commands and files.

    To specify the value of **TZ** for _ascron_ jobs, use **--tz**=_zone_, where _zone_ can be any string (but should be what your _crond_ provides).

    To omit **TZ**, use **--notz**.

- **-L** **--locale**=_specifier_ **--nolocale**

    Specifies the locale from which the default codeset for e-mails is determined.  See [Subtleties](https://metacpan.org/pod/Subtleties), below for details.

- **--version**

    Displays the version number of _ascron_.

- **--help**

    Displays the help sections of the manual.

- **--man**

    Displays the manual.
