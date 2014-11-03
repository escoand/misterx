#!/usr/bin/perl -w
$|++;

use strict;
use warnings;

use File::Copy;
use IO::Handle;
use IO::Socket;
use IO::Select;
use URI::Escape;

# format igc or gpx
my $format = "igc";

# open socket
my $client_sock = IO::Socket::INET->new(
	Listen		=> 20, # max clients
	#LocalAddr	=> "127.0.0.1",
	LocalPort	=> 5005,
	Proto		=> "tcp",
	ReuseAddr	=> 1,
);
my $status_sock = IO::Socket::INET->new(
	Listen		=> 5, # max clients
	LocalAddr	=> "127.0.0.1",
	LocalPort	=> 6006,
	Proto		=> "tcp",
	ReuseAddr	=> 1,
);

# init select
my $read_select  = IO::Select->new();
$read_select->add($client_sock);
$read_select->add($status_sock);
my %clients = ();

# main loop
while(1) {

	# wait for data
	#my @read = $read_select->can_read();   
	foreach my $read ($read_select->can_read()) {

		# status request
		if ($read == $status_sock) {
			my $new_tcp = $read->accept();
			print $new_tcp "HTTP/1.1 200 OK\nConnection: close\n\n[";
			my $i = 1;
			foreach my $client (keys %clients) {
				printf $new_tcp ($i++ > 1 ? "," : "") . "{\"address\":\"%s\"", $client;
				foreach my $attrib (keys %{$clients{$client}}) {
					printf $new_tcp ",\"%s\":\"%s\"", $attrib, $clients{$client}{$attrib};
				}
				print $new_tcp "}";
			}
			print $new_tcp "]";
			$new_tcp->flush;
			#logging("status request");
			$new_tcp->close();
			next;
		}

		# new socket
		if ($read == $client_sock) {
			my $new_tcp = $read->accept();
			$read_select->add($new_tcp);
			my $peeraddr = sprintf "%s:%i", $new_tcp->peerhost(), $new_tcp->peerport();
			$clients{$peeraddr}{status} = "connected";
			#logging($peeraddr . " connected");
			next;
		}

		# read from socket
		my $peeraddr = sprintf "%s:%i", $read->peerhost(), $read->peerport();
		my $data = <$read>;
		my $html = 0;

		# socket closed
		if (!$data) {
			$clients{$peeraddr}{status} = "disconnected";
			$read_select->remove($read);
			$read->close();
			#logging($peeraddr . " disconnected");
			next;
		}

		# data on socket
		$clients{$peeraddr}{time} = localtime();
		$data =~ s/[\r\n]+$//;

		# gts http request
		if($data =~ /^GET .*&id=(.*).*&gprmc=(.*) HTTP\/([0-9.]+)$/) {
			$clients{$peeraddr}{name} = uri_unescape($1);
			$data = uri_unescape($2);
			$html = $3;
		}

		# checksum (xor of every byte)
		if($data !~ s/\$(.*)\*([0-9a-zA-Z]{2})$/$1/) {
			$clients{$peeraddr}{status} = "error";
			logging($peeraddr . " wrong message: " . $data);
		}
		elsif(uc $2 ne strxor($1)) {
			$clients{$peeraddr}{status} = "error";
			logging($peeraddr . " wrong checksum (" . $2 . "!=" . strxor($1) . "): " . $data);
		}

		# PGID,TEST
		#      TEST		Name of device
		elsif($data =~ m/^PGID,(.*)$/) {
			my $filename = $1 . ".gpx";
			$clients{$peeraddr}{name} = $1;
			$clients{$peeraddr}{status} = "renamed";
			#logging($peeraddr . " named " . $1);
		}

		# unknown sender
		elsif(!$clients{$peeraddr}) {
			$clients{$peeraddr}{status} = "unknown";
			logging($peeraddr . " unknown sender");
			$read_select->remove($read);
			$read->close();
			next;
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
			my $dt = sprintf("20%02i-%02i-%02iT%02i:%02i:%02iZ", $13, $12, 11, $1 ,$2, $3);
			my $lat = ($5 eq "S" ? -1 : 1) * ($4 + $4 / 60);
			my $lon = ($9 eq "W" ? -1 : 1) * ($7 + $8 / 60);
			my $speed = $10 * 1.852;
			$clients{$peeraddr}{lat} = $lat;
			$clients{$peeraddr}{lon} = $lon;
			$clients{$peeraddr}{proto} = "GPRMC";
			$clients{$peeraddr}{status} = "ok";
			logpoint($clients{$peeraddr}{name}, $dt, $lat, $lon, $speed);
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
			my $dt = sprintf("%04i-%02i-%02iT%02i:%02i:%02iZ", $1, $2, $3, $4, $5, $6);
			my $speed = $9 * 1.852;
			$clients{$peeraddr}{lat} = $7;
			$clients{$peeraddr}{lon} = $8;
			$clients{$peeraddr}{proto} = "TRCCR";
			$clients{$peeraddr}{status} = "ok";
			logpoint($clients{$peeraddr}{name}, $dt, $7, $8, $speed, $10);
		}

		# wrong data
		else {
			$clients{$peeraddr}{status} = "ERROR";
			logging($peeraddr . " unknown message: " . $data);
			$read_select->remove($read);
			$read->close();
		}

		# http return code
		if($html) {
			while(<$read>) { /^[\r\n]+$/ and last; }
			print $read "HTTP/$html 200 OK\nConnection: close\n\n";
			$clients{$peeraddr}{proto} = "HTML";
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
	my ($name, $dt, $lat, $lon, $speed, $ele) = @_;
	my $filename = $name;
	$filename =~ s/[^A-Za-z0-9 ]/_/g;
	$filename .= "." . $format;

	# gpx format
	if($format eq "gpx") {

		# create file
		if (! -e $filename) {
			open my $fh, ">", $filename;
			print $fh "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n";
			print $fh "<gpx><trk><trkseg>\n";
			print $fh "</trkseg></trk></gpx>\n";
			close $fh;
		}

		# create line
		my $line = sprintf "<trkpt lat=\"%.10f\" lon=\"%.10f\"><time>%s</time>", $lat, $lon, $dt;
		if($speed) {
			$line .= sprintf "<speed>%f</speed>", $speed;
		}
		if($ele) {
			$line .= sprintf "<ele>%f</ele>", $ele;
		}
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
	elsif($format eq "igc") {
		my $fh;

		# create file
		if (! -e $filename) {
			open $fh, ">", $filename;
			print $fh "AXXX perl_gps_logger\r\n";
			printf $fh "HFDTE%02i%02i%02i\r\n", substr($dt, 8, 2), substr($dt, 5, 2), substr($dt, 2, 2);
			printf $fh "HOPLTPILOT: %s\r\n", $filename;
		}

		# write point
		else {
			open $fh, ">>", $filename;
		}
		my $lat_d = int($lat);
		my $lat_m = ($lat - $lat_d) * 60;
		my $lat_s = ($lat_m - int($lat_m)) * 1000;
		my $lon_d = int($lon);
		my $lon_m = ($lon - $lon_d) * 60;
		my $lon_s = ($lon_m - int($lon_m)) * 1000;
		printf $fh "B%02i%02i%02i%02i%02i%03iN%03i%02i%03iEA00000%05i\r\n",
			substr($dt, 11, 2), substr($dt, 14, 2), substr($dt, 17, 2),
			$lat_d, $lat_m, $lat_s, $lon_d, $lon_m, $lon_s, $ele;
	}
}

# log message
sub logging {
	my $dt = localtime();
	printf "%s %s\n", $dt, $_[0];
}