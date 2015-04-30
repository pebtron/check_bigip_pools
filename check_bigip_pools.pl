#
#	The MIT License (MIT)
#
#	Copyright (c) 2014 Timo Schlueter <timo.schlueter@me.com>
#
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#
#	The above copyright notice and this permission notice shall be included in all
#	copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#	SOFTWARE.
#	
#

# Modules
use Getopt::Long qw(:config no_ignore_case);;
use Net::SNMP;

# Environment
my $scriptName = "check_bigip_pools.pl";
my $activeMembers;
my $availableMembers;
my $poolStatus;

# Default Settings
my $snmpPort = 161;
my $snmpVersion = 2;
my $warningLimit = 1;
my $criticalLimit = 0;

# OIDs
my $activeMemberCountOid = "1.3.6.1.4.1.3375.2.2.5.1.2.1.8";
my $availableMemberCountOid = "1.3.6.1.4.1.3375.2.2.5.1.2.1.23";
my $poolAvailabilityCountOid = "1.3.6.1.4.1.3375.2.2.5.5.2.1.2";

sub show_help() {
        print "\n$scriptName plugin for Nagios to monitor the Pool-Status on Big-IP Appliances via SNMP\n";
        print "\nUsage:\n";
        print "   -H (--hostname)      IP or Hostname of the Big-IP\n";
        print "   -P (--poolname)      Name of the Pool\n";
        print "   -C (--community)     SNMP community (default is public)\n";
        print "\nOptional:\n";
        print "   -w (--warning)       Threshold for warning limit\n";
        print "   -c (--critical)      Threshold for critical limit\n";
        print "   -v (--snmpversion)   SNMP version 1 or 2 (default is 2)\n";
        print "   -p (--snmpport)      SNMP port (default is 161)\n";
        print "   -h (--help)          Show this message\n\n";
        print "Copyright (C) 2013 Timo Schlueter (nagios\@timo.in)\n";
        print "$scriptName comes with ABSOLUTELY NO WARRANTY\n";
}

sub main() {
	my $parameters = GetOptions(
		'hostname|H=s' => \$host,
		'poolname|P=s' => \$poolName,
		'community|C=s' => \$community,
		'snmpversion|v=i' => \$snmpVersion,
		'snmpport|p=i' => \$snmpPort,
		'warning|w=i' => \$warningLimit,
		'critical|c=i' => \$criticalLimit,
		'help|h' => \$help
	);

	if ($parameters == 0 || $help){
		show_help;
		exit 3;
	} else {
		if (!$host || !$poolName || !$community) {
			show_help;
		} else {
			$poolOid = $poolName;
			$poolOid =~ s/(.)/sprintf('.%u', ord($1))/eg;

			$session = Net::SNMP->session(
				-hostname => $host, 
				-port => $snmpPort, 
				-version => $snmpVersion,
				-community => $community,
				-timeout => 10
			);

			if (!defined($session)) {
				print "Can't connect to Host (" . $host . "). SNMP related problem.";
				exit 3;
			} else {
				$activeMemberList = $session->get_table($activeMemberCountOid);
				$availableMemberList = $session->get_table($availableMemberCountOid);
				$poolStatusList = $session->get_table($poolAvailabilityCountOid);

				if (!defined($activeMemberList) || !defined($availableMemberList) || !defined($poolStatusList)) {
					print "Can't get status information. SNMP related problem.";
					exit 3;
				} else {
					my $error = 1;
					foreach my $key (keys %$activeMemberList) {
						if (index($key, $poolOid) ne -1) {
							$activeMembers = %$activeMemberList->{$key};
							$error = 0;
						}
					}
					
					foreach my $key (keys %$availableMemberList) {
						if (index($key, $poolOid) ne -1) {
							$availableMembers = %$availableMemberList->{$key};
							$error = 0;
						}
					}

					foreach my $key (keys %$poolStatusList) {
						if (index($key, $poolOid) ne -1) {
							$poolStatus = %$poolStatusList->{$key};
							$error = 0;
						}
					}

					if ($error eq 1) {
						print "Can't find information for specified pool (" . $poolName . "). Please check poolname.";
						exit 3;
					} else {
						if ($poolStatus eq 1) {
							$poolStatus = "available";
						} else {
							$poolStatus = "unknown";
						}

						if ($criticalLimit gt $warningLimit) {
							print "Critical value can't be higher than warning value.";
							exit 3;
						} else {
							my $outputString = " - Pool: " . $poolName . " / Status: ".  $poolStatus . " / Members active: " . $activeMembers . " out of " . $availableMembers;
							if ($activeMembers eq $availableMembers) {
								print "OK" . $outputString;
								exit 0;
							} elsif ($activeMembers le $criticalLimit) {
								print "CRITICAL" . $outputString;
								exit 2;
							} elsif ($activeMembers le $warningLimit) {
								print "WARNING" . $outputString;
								exit 1;
							} else {
								print "OK" . $outputString;
								exit 0;
							}
						}
					}
				}
			}
		}
	}
}

main();
