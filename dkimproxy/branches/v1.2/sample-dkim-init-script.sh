#!/bin/sh
#
# Copyright (c) 2005-2007 Messiah College.
#
### BEGIN INIT INFO
# Default-Start:  3 4 5
# Default-Stop:   0 1 2 6
# Description:    Runs dkimproxy
### END INIT INFO

### BEGIN CONFIGURABLE BITS
DKIMPROXYDIR=/usr/local/dkimproxy
DKIMPROXYUSER=dkim
DKIMPROXYGROUP=dkim
### END CONFIGURABLE BITS

### IF YOU MOVE THE CONFIG FILES, CHANGE THIS:
DKIMPROXY_IN_CFG="$DKIMPROXYDIR/etc/dkimproxy_in.conf"
DKIMPROXY_OUT_CFG="$DKIMPROXYDIR/etc/dkimproxy_out.conf"

if [ ! '(' -f "$DKIMPROXY_IN_CFG" -o -f "$DKIMPROXY_OUT_CFG" ')' ]; then
	echo "Error: one or both of the following files must be created:" >&2
	echo "$DKIMPROXY_IN_CFG" >&2
	echo "$DKIMPROXY_OUT_CFG" >&2
	exit 1
fi

HOSTNAME=`hostname -f`
DKIMPROXY_IN_ARGS="
	--hostname=$HOSTNAME
	--conf_file=$DKIMPROXY_IN_CFG"
DKIMPROXY_OUT_ARGS="
	--conf_file=$DKIMPROXY_OUT_CFG"

DKIMPROXY_COMMON_ARGS="
	--user=$DKIMPROXYUSER
	--group=$DKIMPROXYGROUP
	--daemonize"

DKIMPROXY_IN_BIN="$DKIMPROXYDIR/bin/dkimproxy.in"
DKIMPROXY_OUT_BIN="$DKIMPROXYDIR/bin/dkimproxy.out"

PIDDIR=$DKIMPROXYDIR/var/run
DKIMPROXY_IN_PID=$PIDDIR/dkimproxy_in.pid
DKIMPROXY_OUT_PID=$PIDDIR/dkimproxy_out.pid

case "$1" in
	start-in)
		echo -n "Starting inbound DKIM-proxy (dkimproxy.in)..."

		# create directory for pid files if necessary
		test -d $PIDDIR || mkdir -p $PIDDIR || exit 1

		# start the daemon
		$DKIMPROXY_IN_BIN $DKIMPROXY_COMMON_ARGS --pidfile=$DKIMPROXY_IN_PID $DKIMPROXY_IN_ARGS
		RETVAL=$?
		if [ $RETVAL -eq 0 ]; then
			echo done.
		else
			echo failed.
			exit $RETVAL
		fi
		;;

	start-out)
		echo -n "Starting outbound DKIM-proxy (dkimproxy.out)..."

		# create directory for pid files if necessary
		test -d $PIDDIR || mkdir -p $PIDDIR || exit 1

		# start the daemon
		$DKIMPROXY_OUT_BIN $DKIMPROXY_COMMON_ARGS --pidfile=$DKIMPROXY_OUT_PID $DKIMPROXY_OUT_ARGS
		RETVAL=$?
		if [ $RETVAL -eq 0 ]; then
			echo done.
		else
			echo failed.
			exit $RETVAL
		fi
		;;

	start)
		test -f $DKIMPROXY_IN_CFG && { $0 start-in || exit $?; }
		test -f $DKIMPROXY_OUT_CFG && { $0 start-out || exit $?; }
		;;

	stop-in)
		echo -n "Shutting down inbound DKIM-proxy (dkimproxy.in)..."
		if [ -f $DKIMPROXY_IN_PID ]; then
			kill `cat $DKIMPROXY_IN_PID` && rm -f $DKIMPROXY_IN_PID
			RETVAL=$?
			[ $RETVAL -eq 0 ] && echo done. || echo failed.
			exit $RETVAL
		else
			echo not running.
		fi
		;;

	stop-out)
		echo -n "Shutting down outbound DKIM-proxy (dkimproxy.out)..."
		if [ -f $DKIMPROXY_OUT_PID ]; then
			kill `cat $DKIMPROXY_OUT_PID` && rm -f $DKIMPROXY_OUT_PID
			RETVAL=$?
			[ $RETVAL -eq 0 ] && echo done. || echo failed.
			exit $RETVAL
		else
			echo not running.
		fi
		;;

	stop)
		test -f $DKIMPROXY_IN_CFG && { $0 stop-in || exit $?; }
		test -f $DKIMPROXY_OUT_CFG && { $0 stop-out || exit $?; }
		;;

	restart)
		$0 stop && $0 start || exit $?
		;;

	status-in)
		echo -n "dkimproxy.in..."
		if [ -f $DKIMPROXY_IN_PID ]; then
			pid=`cat $DKIMPROXY_IN_PID`
			if ps -ef |grep -v grep |grep -q "$pid"; then
				echo " running (pid=$pid)"
			else
				echo " stopped (pid=$pid not found)"
			fi
		else
			echo " stopped"
		fi
		;;

	status-out)
		echo -n "dkimproxy.out..."
		if [ -f $DKIMPROXY_OUT_PID ]; then
			pid=`cat $DKIMPROXY_OUT_PID`
			if ps -ef |grep -v grep |grep -q "$pid"; then
				echo " running (pid=$pid)"
			else
				echo " stopped (pid=$pid not found)"
			fi
		else
			echo " stopped"
		fi
		;;

	status)
		test -f $DKIMPROXY_IN_CFG && { $0 status-in || exit $?; }
		test -f $DKIMPROXY_OUT_CFG && { $0 status-out || exit $?; }
		;;
	*)
		echo "Usage: $0 {start|stop|restart|status}"
		exit 1
		;;
esac
