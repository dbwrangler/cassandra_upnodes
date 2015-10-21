#!/bin/bash
#
usage() {
cat << EOF
Usage: $0 -h <host> -j <port> -w <warning> -c <critical> -d <datacenter>

 -h <host> IP address or hostname of the cassandra node to connect, localhost by default.
 -j <port> JMX port, 7199 by default.
 -w <warning> number of missing nodes to warn on
 -c <critical> number of missing nodes to go critical on
 -d datacenter name
 -h show command option
 -V show command version

EOF
exit 3
}

# Checking the status, outputting the nagios status code
check_status() {
case $retval in
  0 )
  echo "OK - Live Node:$live_node - ${verbose[*]} | ${performance[*]}"
  exit 0
  ;;

  1 )
  echo "WARNING - Live Node:$live_node - ${verbose[*]} | ${performance[*]}"
  exit 1
  ;;

  2 )
  echo "CRITICAL - Live Node:$live_node - ${verbose[*]} | ${performance[*]}"
  exit 2
  ;;

  3 )
  echo "UNKNOWN - Live Node:$live_node - ${verbose[*]} | ${performance[*]}"
  exit 3
  ;;

esac
}


# ------------------------------------------------------------
# variables
# ------------------------------------------------------------
export LANG=C
opt_v=1.00
date=$(date '+%Y%m%d')

host="localhost"
port="7199"


# option definitions
while getopts "d:c:w:H:P:hV" opt ; do
  case $opt in
  d )
  datacenter="$OPTARG"
  ;;

  c )
  critical="$OPTARG"
  ;;

  w )
  warning="$OPTARG"
  ;;

  H )
  host="$OPTARG"
  ;;

  P )
  port="$OPTARG"
  ;;

  h )
  usage
  ;;

  V )
  echo "`basename $0` $opt_v" ; exit 0
  ;;

  * )
  usage
  ;;

  esac
done
shift `expr $OPTIND - 1`


# verify warning and critical are number
expr $warning + 1 >/dev/null 2>&1
if [ "$?" -lt 2 ]; then
  true
else
  echo "-c <critical> $critical must be number."
  exit 3
fi

expr $critical + 1 >/dev/null 2>&1
if [ "$?" -lt 2 ]; then
  true
else
  echo "-c <critical> $critical must be number."
  exit 3
fi

# verify warning is less than critical
if [ $warning -ge $critical ]; then
  echo "-w <warning> $warning must be less than -c <critical> $critical."
  exit 3
fi


# ------------------------------------------------------------
# begin script
# ------------------------------------------------------------
# check the number of live node, status and performance

node_count=$(dsetool status|grep $datacenter|wc -l)
live_node=$(dsetool -h $host -j $port status|grep $datacenter|grep -c 'Up')
verbose=($(dsetool -h $host -j $port status|grep $datacenter| awk '/Up/ {print $1":"$5","$6","$7$8","$9 " " }'))
performance=($(dsetool -h $host -j $port status|grep $datacenter| awk '/Up/ {print "Load_"$1"="$9",Owns_"$1"="$9}'))
unavailable_nodes=$(($node_count-$live_node))

# unless live node is number, reply unknown code
expr $live_node + 1 >/dev/null 2>&1
if [ "$?" -lt 2 ]; then
  true
else
  retval=3
fi

# verify the number of unavailable nodes is more or equal to critical, warning
if [ "$unavailable_nodes" -ge "$critical" ]; then
#if [ "$live_node" -le "$critical" ]; then
  retval=2
else
  if [ "$unavailable_nodes" -ge "$warning" ]; then
    retval=1
  else
    retval=0
  fi
fi

check_status

