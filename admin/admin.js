var colors = [
	"#ff0000",	// 01 red
	"#00ff00",	// 02 green
	"#0000ff",	// 03 blue
	"#ffff00",	// 04 yellow
	"#ff00ff",	// 05 magenta
	"#00ffff",	// 06 purple
	"#ff8000",	// 07 orange
	"#ff0080",	// 08 lila
	"#000000",	// 09 black
	"#ffffff",	// 10 white
	"#848484",	// 11 grey
];

// admin function
function admin() {
	map.addOverlay(new ol.Overlay({element: document.getElementById("popup")}));
	map.on("click", function(evt) {
		var coord = ol.proj.transform(evt.coordinate, "EPSG:3857", "EPSG:4326");

		// calc coord minutes
		coord[2] = (coord[0] - Math.floor(coord[0])) * 60;
		coord[3] = (coord[1] - Math.floor(coord[1])) * 60;

		// generate data
		var now = new Date();
		var data = "GPRMC," +
			(now.getHours() <= 9 ? "0" : "") + now.getHours() +
			(now.getMinutes() <= 9 ? "0" : "") + now.getMinutes() +
			(now.getSeconds() <= 9 ? "0" : "") + now.getSeconds() +
			",A," + // always A
			Math.floor(coord[1]) + // lat minutes
			(coord[3] <= 9 ? "0" : "") + coord[3] + // lat seconds
			",N," +  // north
			Math.floor(coord[0]) + // lon minutes
			(coord[2] <= 9 ? "0" : "") + coord[2] + // lon seconds
			",E," + // east
			"0," + // speed
			"0," + // course
			(now.getDate() <= 9 ? "0" : "") + now.getDate() +
			(now.getMonth() + 1 <= 9 ? "0" : "") + (now.getMonth() + 1) +
			(now.getYear() - 100 <= 9 ? "0" : "") + (now.getYear() - 100) +
			",,M";

		// xor data
		var xor = 0;
		for(var i = 0; i < data.length; i++)
			xor = xor ^ data.charCodeAt(i);
		xor = (xor < 16 ? "0" : "") + Number(xor).toString(16).toUpperCase();

		// data to popup
		document.getElementById("data").value = "$" + data + "*" + xor;
		document.getElementById("dropdown").options.length = 0;
		for(var i in map.getLayers().getArray()[2].getSource().getFeatures()) {
			var name = map.getLayers().getArray()[2].getSource().getFeatures()[i].get("name");
			document.getElementById("dropdown").options[document.getElementById("dropdown").length] = new Option(name, name, false, true);
		}

		// popup
		document.getElementById("popup").style.display = "block";
		map.getOverlays().getArray()[0].setPosition(evt.coordinate);
	});

	// close popup
	document.getElementById("popup-closer").onclick = function() {
		document.getElementById("popup").style.display = "none";
		return false;
	};

	// refresh status
	refreshClients();
	window.setInterval(refreshClients, 15000);
}

// client status
function refreshClients() {
	_request("/admin/status/", function() { if(this.readyState==4 && this.status==200) {
		var clients = JSON.parse(this.responseText);

		// clear
		while(map.getLayers().getLength() > 3)
			map.removeLayer(map.getLayers().getArray()[3]);
		var elems = document.getElementById("clients").getElementsByTagName("tr");
		while(elems.length > 1)
			document.getElementById("clients").removeChild(elems[1]);

		// request status
		for(var i = 0; i < clients.length; i++) {

			// position
			if(clients[i]["lat"] && clients[i]["lon"]) {
				var coord = ol.proj.transform([clients[i]["lon"],clients[i]["lat"]], "EPSG:4326", "EPSG:3857");
				var feat = new ol.Feature({
					geometry: new ol.geom.Point(coord),
					name: clients[i]["name"],
				});
				feat.setStyle(new ol.style.Style({
					image: new ol.style.Icon({
						anchor: [0.5, 1],
						anchorXUnits: "fraction",
						anchorYUnits: "fraction",
						opacity: 1,
						src: "http://maps.google.com/mapfiles/kml/pal3/icon" + i + ".png",
					}),
				}));
				map.getOverlays().getArray()[0].addFeature(feat);
				map.getLayers().getArray()[2].getSource().addFeature(feat);
			}

			// trace
			if(clients[i]["file"]) {
				map.addLayer(new ol.layer.Vector({
					source: new ol.source.GPX({
						projection: "EPSG:3857",
						url: clients[i]["file"],
					}),
					style: new ol.style.Style({
						stroke: new ol.style.Stroke({
							color: colors[i],
						}),
					}),
				}));
			}

			// status (iocns at https://www.iconfinder.com/iconsets/fatcow)
			var row = document.createElement("tr");
			var cell1 = document.createElement("td");
			var cell2 = document.createElement("td");
			var cell3 = document.createElement("td");
			var cell4 = document.createElement("td");
			var stat = document.createElement("img");
			stat.src = clients[i]["status"] + ".png";
			stat.alt = clients[i]["status"];
			cell1.appendChild(document.createTextNode(clients[i]["name"]));
			cell2.appendChild(document.createTextNode(clients[i]["address"]));
			cell3.appendChild(document.createTextNode(clients[i]["time"]));
			cell4.appendChild(stat);
			row.appendChild(cell1);
			row.appendChild(cell2);
			row.appendChild(cell3);
			row.appendChild(cell4);
			document.getElementById("clients").appendChild(row);
		}
	}});
}

// submit position
function submit() {
	var url = "/admin/position/?admin=true&id=" +
		encodeURIComponent(document.getElementById("misterx").value) +
		"&gprmc=" + encodeURIComponent(document.getElementById("data").value);
	_request(url, function() {
		if(this.readyState==4 && this.status==200)
			document.getElementById("popup").style.display = "none";
		else if(this.readyState==4)
			alert(this.status + " " + this.statusText);
	});
}

// async http request
function _request(url, callback) {
	var xmlhttp = null;
	if (window.XMLHttpRequest)
		xmlhttp = new XMLHttpRequest();
	else if (window.ActiveXObject)
		xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
	xmlhttp.open("GET", url, true);
	xmlhttp.send(null);
	xmlhttp.onreadystatechange = callback;
}
