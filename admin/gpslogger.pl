#!/usr/bin/perl -w
$|++;

use strict;
use warnings;

use File::Copy;
use IO::Handle;
use IO::Socket;
use IO::Select;
use POSIX qw(strftime);
use URI::Escape;

# track positions (gpx, igc)
my $trackformat = "igc";
my $trackdir = "tracks";
# dump last positions (geojson, kml)
my $dumpformat = "geojson";
my $dumpfile = "../map/positions.json";
my $dumpwait = 300;

# open socket
my $client_sock = IO::Socket::INET->new(
	Listen		=> 20, # max clients
	#LocalAddr	=> "127.0.0.1",
	LocalPort	=> 5055,
	Proto		=> "tcp",
	ReuseAddr	=> 1,
);

# init select
my $read_select = IO::Select->new();
$read_select->add($client_sock);
my %clients = ();
my %nmeaclients = ();
my $lastdumptime = 0;

# main loop
while(1) {

	# wait for data
	foreach my $read ($read_select->can_read()) {

		# new socket
		if($read == $client_sock) {
			my $new_tcp = $read->accept();
			my $peeraddr = sprintf "%s:%i", $new_tcp->peerhost(), $new_tcp->peerport();
			logging($peeraddr . " connect");
			$read_select->add($new_tcp);
			next;
		}

		# read from socket
		my $peeraddr = sprintf "%s:%i", $read->peerhost(), $read->peerport();
		my $data = <$read>;
		$data =~ s/[\r\n]+$// if $data;
		while(<$read>) { /^[\r\n]+$/ and last; }

		# socket closed
		if(!$data) {
			logging($peeraddr . " disconnect");
			$read_select->remove($read);
			$read->close();
			next;
		}

		# dump positions
		if ($lastdumptime < time - $dumpwait) {
			logging("dump positions");
			open my $fh, ">", $dumpfile;
			dumpclients($fh, $dumpformat, 0);
			close $fh;
			$lastdumptime = time;
		}

		# status request
		if($data =~ /^GET \/status(|\/[^ ]*|\?[^ ]*) (HTTP\/[0-9.]+)$/) {
			logging($peeraddr . " status request");
			logging($peeraddr . " disconnect");
			print $read "$2 200 OK\n";
			print $read "Content-type: application/json\n";
			print $read "Cache-Control: no-cache, must-revalidate\n";
			print $read "Pragma: no-cache\n";
			print $read "Expires: Sat, 1 Jan 1970 00:00:00 GMT\n\n";
			dumpclients($read, "geojson", 1);
			$read_select->remove($read);
			$read->flush();
			$read->close();
		}

		# http request
		# GET /?id=311251&timestamp=1443437579&lat=50.70694738&lon=12.45908671&speed=0.0&bearing=0.0&altitude=377.0&batt=46.0 HTTP/1.1
		elsif($data =~ /^GET \/\?id=(.*)&timestamp=(\d+)&lat=(\d+\.\d+)&lon=(\d+\.\d+)&speed=(\d+\.\d+)&bearing=(\d+\.\d+)&altitude=(\d+\.\d+)&batt=(\d+\.\d+) (HTTP\/[0-9.]+)$/) {
			my $name = uri_unescape($1);
			$clients{$name}{time} = $2;
			$clients{$name}{lat} = $3;
			$clients{$name}{lon} = $4;
			$clients{$name}{speed} = $5;
			$clients{$name}{bearing} = $6;
			$clients{$name}{elevation} = $7;
			$clients{$name}{battery} = $8;
			$clients{$name}{protocol} = $9;
			logpoint($name);
			logging($peeraddr . " http update " . $name);
			logging($peeraddr . " disconnect");

			print $read "$9 200 OK\n\n";
			$read_select->remove($read);
			$read->flush();
			$read->close();
		}

		# gts http request
		elsif($data =~ /^GET (|.*[&?])id=(.*).*&gprmc=(.*) (HTTP\/[0-9.]+)$/) {
			my $name = uri_unescape($2);
			$data = uri_unescape($3);
			logging($peeraddr . " gts update " . $name);
			logging($peeraddr . " disconnect");

			print $read "$4 200 OK\n";
			$read_select->remove($read);
			$read->flush();
			$read->close();
		}

		# nmea 0183 request (or like)
		elsif($data =~ s/\$((PGID|GPRMC|TRCCR),.*)\*([0-9a-zA-Z]{2})$/$1/) {

			# checksum (xor of every byte)
			if(uc $2 ne strxor($1)) {
				logging($peeraddr . " wrong checksum (" . $2 . "!=" . strxor($1) . "): " . $data);
			}

			# PGID,TEST
			#      TEST		Name of device
			elsif($data =~ m/^PGID,(.*)$/) {
				logging($peeraddr . " named " . $1);
				$nmeaclients{$peeraddr} = $1;
			}

			# unknown sender
			elsif(!$nmeaclients{$peeraddr}) {
				logging($peeraddr . " unknown sender");
				logging($peeraddr . " disconnect");
				$read_select->remove($read);
				$read->close();
			}

			# $GPRMC,225446,A,4916.45,N,12311.12,W,000.5,054.7,191194,020.3,E*68
			#        225446								Time of fix 22:54:46 UTC ($1-$3)
			#               A							Navigation receiver warning A = OK, V = warning
			#                 4916.45,N						Latitude 49 deg. 16.45 min North ($4-$6)
			#                           12311.12,W					Longitude 123 deg. 11.12 min West ($7-$9)
			#                                      000.5				Speed over ground, Knots ($10)
			#                                            054.7			Course Made Good, True
			#                                                  191194		Date of fix 19 November 1994 ($11-$13)
			#                                                         020.3,E	Magnetic variation 20.3 deg East ($14-$17)
			# GPRMC,130210.000,A,5043.0671,N,01230.0648,E,2.68,68.91,111014,,
			# GPRMC,135124.983,A,5042.1623,N,01226.2633,E,0.00,0.00,131014,,
			elsif($data =~ m/^GPRMC,(\d\d)(\d\d)(\d\d[\d\.]*),[AV],(\d*)(\d\d\.\d+),([NS]),(\d*)(\d\d\.\d+),([EW]),([\d\.]+),[\d\.]+,(\d\d)(\d\d)(\d\d),((\d*)(\d\d\.\d+),([NSEW]))?,[ADEMSN]?$/) {
				my $dt = sprintf("20%02i-%02i-%02iT%02i:%02i:%02iZ", $13, $12, $11, $1 ,$2, $3);
				my $lat = ($5 eq "S" ? -1 : 1) * ($4 + $4 / 60);
				my $lon = ($9 eq "W" ? -1 : 1) * ($7 + $8 / 60);
				my $speed = $10 * 1.852;
				$clients{$nmeaclients{$peeraddr}}{lat} = $lat;
				$clients{$nmeaclients{$peeraddr}}{lon} = $lon;
				$clients{$nmeaclients{$peeraddr}}{protocol} = "GPRMC";
				$clients{$nmeaclients{$peeraddr}}{time} = time;
				logpoint($nmeaclients{$peeraddr});
				logging($peeraddr . " gprmc update " . $nmeaclients{$peeraddr});
			}

			# $TRCCR,20140111000000.000,A,60.000000,60.000000,0.00,0.00,0.00,50,*3a
			#        20140111000000.000						Date and tim of fix 2014-01-11 00:00:00.000 UTC ($1-$6)
			#                           A						Navigation receiver warning A = OK, V = warning
			#                             60.000000					Latitude in degrees 60 deg (negative for south hemisphere) ($7)
			#                                       60.000000			Longitude in degrees 60 deg (negative for west hemisphere) ($8)
			#                                                 0.00			Speed over ground, Knots ($9)
			#                                                      0.00		Course Made Good, True
			#                                                           0.00	Altitude in meters ($10)
			#                                                                50	Battery level
			#                                                                   *3a	Checksum
			# TRCCR,20141013135417.016,A,50.699590,12.436616,0.00,0.00,0.00,80,
			elsif($data =~ m/^TRCCR,(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d[\d\.]*),[AV],([\d\.]+),([\d\.]+),([\d\.]+),[\d\.]+,([\d\.]+),[\d\.]+,$/) {
				logging($peeraddr . " trccr update");
				my $dt = sprintf("%04i-%02i-%02iT%02i:%02i:%02iZ", $1, $2, $3, $4, $5, $6);
				my $speed = $9 * 1.852;
				$clients{$nmeaclients{$peeraddr}}{lat} = $7;
				$clients{$nmeaclients{$peeraddr}}{lon} = $8;
				$clients{$nmeaclients{$peeraddr}}{protocol} = "TRCCR";
				$clients{$nmeaclients{$peeraddr}}{time} = time;
				logpoint($nmeaclients{$peeraddr});
			}
		}

		# unknown message
		else {
			logging($peeraddr . " unknown message: " . $data);
			logging($peeraddr . " disconnect");
			$read_select->remove($read);
			$read->close();
		}
	}
}

# xor all characters
sub strxor {
	my $str = $_[0];
	my $sum = 0;
	for(my $i = 0; $i < length($str); $i++) {
		$sum = $sum ^ ord(substr($str, $i, 1));
	}
	return sprintf("%02X", $sum);
}

# log point
sub logpoint {
	my $name = $_[0];
	my $filename = $name;
	$filename =~ s/[^A-Za-z0-9 ]+/_/g;
	$filename = $trackdir . "/" . $filename . "." . $trackformat;

	# gpx format
	if($trackformat eq "gpx") {

		# create file
		if (! -e $filename) {
			open my $fh, ">", $filename;
			print $fh "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n";
			print $fh "<gpx><trk><trkseg>\n";
			print $fh "</trkseg></trk></gpx>\n";
			close $fh;
		}

		# create line
		my $line = sprintf "<trkpt lat=\"%.10f\" lon=\"%.10f\">", $clients{$name}{lat}, $clients{$name}{lon};
		$line .= sprintf "<time>%s</time>", strftime("%Y-%m-%d %H:%M:%S", localtime($clients{$name}{time})) if $clients{$name}{time};
		$line .= sprintf "<speed>%f</speed>", $clients{$name}{speed} if $clients{$name}{speed};
		$line .= sprintf "<ele>%f</ele>", $clients{$name}{elevation} if $clients{$name}{elevation};
		$line .= "</trkpt>\n";

		# write temp file
		open my $fh1, "<", $filename;
		open my $fh2, ">", $filename.".tmp";
		while(<$fh1>) {
			s/<\/trkseg>/$line$&/;
			print $fh2 $_;
		}
		close $fh2;
		close $fh1;

		# move temp file
		move $filename.".tmp", $filename;
	}

	# igc format
	elsif($trackformat eq "igc") {
		my $fh;

		# create file
		if (! -e $filename) {
			open $fh, ">", $filename;
			print $fh "AXXX perl_gps_logger\n";
			printf $fh strftime("HFDTE%d%m%y", localtime($clients{$name}{time})) . "\n";
			printf $fh "HOPLTPILOT: %s\n", $filename;
		}

		# write point
		else {
			open $fh, ">>", $filename;
		}
		my $lat_d = int($clients{$name}{lat});
		my $lat_m = ($clients{$name}{lat} - $lat_d) * 60;
		my $lat_s = ($lat_m - int($lat_m)) * 1000;
		my $lon_d = int($clients{$name}{lon});
		my $lon_m = ($clients{$name}{lon} - $lon_d) * 60;
		my $lon_s = ($lon_m - int($lon_m)) * 1000;
		printf $fh "B%s%02i%02i%03iN%03i%02i%03iEA00000%05i\n",
			strftime("%H%M%S", localtime($clients{$name}{time})),
			$lat_d, $lat_m, $lat_s, $lon_d, $lon_m, $lon_s,
			($clients{$name}{ele} ? $clients{$name}{ele} : 0);
	}
}

# dump last positions
sub dumpclients {
	my ($fh, $format, $full) = @_;
	my $cnt = 0;

	# kml format
	if ($format eq "kml") {
		print $fh "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
		print $fh "<kml xmlns=\"http://www.opengis.net/kml/2.2\">";
		print $fh "<Document>";
		foreach my $client (keys %clients) {
			printf $fh "<Placemark><name>%s</name><Point><coordinates>%s,%s,0</coordinates></Point><styleUrl>#%s%i</styleUrl></Placemark>",
				$client, $clients{$client}{lon}, $clients{$client}{lat}, "pin", ++$cnt;
		}
		print $fh "</Document>";
		print $fh "</kml>";
	}

	# geojson format
	elsif ($format eq "geojson") {
		print $fh '{"type":"FeatureCollection","features":[';
		foreach my $client (keys %clients) {
			printf $fh "," if $cnt++ > 0;
			printf $fh '{"type":"Feature","geometry":{"type":"Point","coordinates":[%s,%s]},"properties":{"title":"%s","time":"%s"',
				$clients{$client}{lon}, $clients{$client}{lat}, $client, strftime("%Y-%m-%d %H:%M:%S", localtime($clients{$client}{time}));
			if($full) {
				my $desc = "";
				foreach my $attrib (keys %{$clients{$client}}) {
					next if $attrib eq "lat" or $attrib eq "lon" or $attrib eq "time";
					$desc .= $attrib . ": " . $clients{$client}{$attrib} . "<br/>";
				}
				printf $fh ',"description":"%s"', $desc;
			}
			printf $fh "}}";
		}
		print $fh "]}";
	}
}

# log message
sub logging {
	printf "%s %s\n", strftime("%Y-%m-%d %H:%M:%S", localtime), $_[0];
}
