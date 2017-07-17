#!/bin/bash
scriptname="$(basename "${BASH_SOURCE[0]}")"
rundir="${XDG_RUNTIME_DIR:-${HOME}/.local/var/run}/${scriptname}"
pidfile="${rundir}/PID"
cleanup () {
    rm -f "${pidfile}"
    flock -u 200
}
mkdir -p "${rundir}"
exec 200>"${pidfile}"
if ! flock -n 200 || ! echo "$$" > "${pidfile}"; then
    echo "another instance of the ${scriptname} is currently running..." >&2
    exit 1
fi
trap cleanup EXIT HUP INT QUIT TERM

# Set secure permissions on created directories and files
umask 077

mkdir -p "${XDG_CONFIG_HOME}/anacron/cron.daily"
mkdir -p "${XDG_CONFIG_HOME}/anacron/cron.weekly"
mkdir -p "${XDG_CONFIG_HOME}/anacron/cron.monthly"

spooldir="${HOME}/.local/var/spool/anacron"
mkdir -p "${spooldir}"

anacrontab="${XDG_CONFIG_HOME}/anacron/anacrontab"

[ -f "$anacrontab" ] || exit 0

anacron -d -t "${anacrontab}" -S "${spooldir}"
