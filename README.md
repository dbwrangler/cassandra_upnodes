# cassandra_upnodes
For use with tools like nagios
Forked but with inverted logic from harisekhon.
Uses dsetool to easily isolate down nodes for a given input DC
Checks for nodes unavailable. 
Use:

check_cassandra_cluster.sh -w 1 -c 2 -d datacenter_name
