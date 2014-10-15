check\_bigip\_pools.pl
=================

This Nagios/Icinga check can be used to monitor pool availability and member status on Big-IP hardware. It uses SNMP (v1 or v2) to get the information from the Big-IP.
The Script is completely written in Perl and has been tested on a Big-IP LTM 1600 with OS version 11.1. 

The default settings return a WARNING if there is only one pool member active and CRITICAL if no pool member is active. This behaviour can be changed with optional parameters. 


#Requirements: 
- Getopt::Long 
- Net::SNMP 

#Parameters: 
-H (--hostname) IP or Hostname of the Big-IP 
-p (--poolname) Name of the Pool 
-C (--community) SNMP community (default is public) 

###Optional: 
-w (--warning) Threshold for warning limit 
-c (--critical) Threshold for critical limit 
-v (--snmpversion) SNMP version 1 or 2 (default is 2) 
-p (--snmpport) SNMP port (default is 161) 
-h (--help) Show this message 

#Usage/Example: 
check_bigip_pools.pl -H hostname -P poolname -C snmpcommunity [ -w warning | -c critical | -p snmpport | -v snmpversion ] 
