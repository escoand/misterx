#!/bin/sh

# config
TYPE=pin
LON_MIN=12.4677075723
LON_MAX=12.5079142655
LON_PARTS=12.744
LAT_MIN=50.7109981848
LAT_MAX=50.7289978253
LAT_PARTS=9
I=1

# head
cat <<END
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
END
if [ "$1" = "ROUND" ]; then
	cat <<END
<Style id="dot1"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/pal3/icon0.png</href></Icon><hotSpot x="1.55" y="-0.2" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="dot2"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/pal3/icon1.png</href></Icon><hotSpot x="0.85" y="-0.2" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="dot3"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/pal3/icon2.png</href></Icon><hotSpot x="0.15" y="-0.2" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="dot4"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/pal3/icon3.png</href></Icon><hotSpot x="-0.55" y="-0.2" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="dot5"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/pal3/icon4.png</href></Icon><hotSpot x="1.55" y="0.425" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="dot6"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/pal3/icon5.png</href></Icon><hotSpot x="0.85" y="0.425" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="dot7"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/pal3/icon6.png</href></Icon><hotSpot x="0.15" y="0.425" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="dot8"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/pal3/icon7.png</href></Icon><hotSpot x="-0.55" y="0.425" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="dot9"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/pal3/icon16.png</href></Icon><hotSpot x="1.55" y="1.05" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="dot10"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/pal3/icon17.png</href></Icon><hotSpot x="0.85" y="1.05" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="dot11"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/pal5/icon48.png</href></Icon><hotSpot x="0.15" y="1.05" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="dot12"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/pal5/icon49.png</href></Icon><hotSpot x="-0.55" y="1.05" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
END
else
	cat <<END
<Style id="pin1"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/paddle/1.png</href></Icon><hotSpot x="0.5" y="0" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="pin2"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/paddle/2.png</href></Icon><hotSpot x="0.5" y="0" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="pin3"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/paddle/3.png</href></Icon><hotSpot x="0.5" y="0" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="pin4"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/paddle/4.png</href></Icon><hotSpot x="0.5" y="0" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="pin5"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/paddle/5.png</href></Icon><hotSpot x="0.5" y="0" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="pin6"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/paddle/6.png</href></Icon><hotSpot x="0.5" y="0" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="pin7"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/paddle/7.png</href></Icon><hotSpot x="0.5" y="0" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="pin8"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/paddle/8.png</href></Icon><hotSpot x="0.5" y="0" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="pin9"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/paddle/9.png</href></Icon><hotSpot x="0.5" y="0" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="pin10"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/paddle/10.png</href></Icon><hotSpot x="0.5" y="0" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="pin11"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/paddle/A.png</href></Icon><hotSpot x="0.5" y="0" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
<Style id="pin12"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/paddle/B.png</href></Icon><hotSpot x="0.5" y="0" xunit="fraction" yunit="fraction" /><scale>0.5</scale></IconStyle></Style>
END
fi

# list
for F in ~/misterx/traces/*.gpx; do
	grep -H '<trkpt ' "$F" |
	tail -n1 |
	tr ':<>"' '\t\t\t\t' |
	cut -f1,4,6 |
	sed 's/\.gpx//'
done 2>/dev/null |
while IFS='	' read FILE LAT LON; do
	FILE=$(basename "$FILE" .gpx)

	#round
	if [ "$1" = "ROUND" ]; then
		TYPE=dot
		LON=$(perl -e "my \$diff=($LON_MAX-$LON_MIN)/$LON_PARTS; print $LON_MIN+\$diff/2+\$diff*int(($LON-$LON_MIN)/\$diff)")
		LAT=$(perl -e "my \$diff=($LAT_MAX-$LAT_MIN)/$LAT_PARTS; print $LAT_MIN+\$diff/2+\$diff*int(($LAT-$LAT_MIN)/\$diff)")
	fi
	
	# output
	echo "<Placemark><name>$FILE</name><Point><coordinates>$LON,$LAT,0</coordinates></Point><styleUrl>#$TYPE$I</styleUrl></Placemark>"
	I=$((I+1))
done

# foot
cat <<END
</Document>
</kml>
END
