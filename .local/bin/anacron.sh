#!/bin/bash
scriptname="$(basename $0)"

lockdir="${XDG_RUNTIME_DIR:-${HOME}/.local/var/lock}/${scriptname}.lock"
pidfile="${lockdir}/PID"
if mkdir ${lockdir} &> /dev/null; then
    trap "rm -rf ${lockdir}" EXIT SIGHUP SIGINT SIGQUIT SIGTERM
    echo "$$" > ${pidfile}
else
    otherpid=$(cat ${pidfile} 2>/dev/null)
    othercmd=$(ps --no-headers --format command --pid ${otherpid} 2>/dev/null)
    if [[ "${othercmd}" =~ .*${scriptname}.* ]]; then
        if [ $(ps --no-headers -C ${scriptname} | wc -l) -ge 10 ]; then
            echo "too many ${scriptname} processes waiting for lock"
            exit 1
        fi
        sleep 1
    else
        rm -rf ${lockdir}
    fi
    exec "$0" "$@"
fi

# Set secure permissions on created directories and files
umask 077

mkdir -p ${XDG_CONFIG_HOME}/anacron/cron.daily
mkdir -p ${XDG_CONFIG_HOME}/anacron/cron.weekly
mkdir -p ${XDG_CONFIG_HOME}/anacron/cron.monthly

spooldir=${HOME}/.local/var/spool/anacron
mkdir -p $spooldir

anacrontab=${XDG_CONFIG_HOME}/anacron/anacrontab

[ ! -f "$anacrontab" ] && exit 0

anacron -d -t $anacrontab -S $spooldir
