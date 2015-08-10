var refreshInterval = 20;
var imgBounds = [[50.711, 12.4677], [50.729, 12.5079]];

var map = null;
var markers = Array();

// init after load
document.addEventListener("load", init, false);
document.addEventListener("DOMContentLoaded", init, false);
function init() {
	map = L.map("map").fitBounds(imgBounds);

	// sidebar
	var sidebar = L.control.sidebar("sidebar", {position: "right"}).addTo(map);

	// map
	L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6IjZjNmRjNzk3ZmE2MTcwOTEwMGY0MzU3YjUzOWFmNWZhIn0.Y8bhBaUMqFiPrDRW9hieoQ', {
		maxZoom: 17,
		id: 'mapbox.streets'
	}).addTo(map);

	// overlay
	//L.imageOverlay("http://daten.ec-hasslau.de/misterx/2014/spielfeld.png", imgBounds).addTo(map);

	// positions
	var realtime = L.realtime({
		url: 'positions.geojson',
		type: 'json'
	}, {
		interval: refreshInterval * 1000,
		getFeatureId: function(feature) { return feature.properties.name; },
		pointToLayer: function(feature, latlng) {

			// create marker icon
			if(!markers[feature.properties.name])
				markers[feature.properties.name] = L.marker(latlng, {
					icon: new L.Icon({
						iconUrl: icons[Object.keys(markers).length + 1],
						iconSize: [32, 32],
						iconAnchor: [16, 32],
						popupAnchor: [16, -32],
					})
				});

			// return marker icon
			return markers[feature.properties.name];
		},
		onEachFeature: function (feature, layer) { layer.bindPopup(feature.properties.name); }
	}).addTo(map);

	// refresh
	refresh();
	window.setInterval("refresh()", refreshInterval * 1000);
}

function refresh() {
	reqwest({
		url: "../admin/status",
		type: "json",
		contentType: "application/json",
		success: function (resp) {
			var elems = document.getElementById("clients_table").getElementsByTagName("tr");
			while(elems.length > 1)
				document.getElementById("clients_table").removeChild(elems[1]);

			// request status
			for(var i = 0; i < resp.length; i++) {
				var row1 = document.createElement("tr");
				var row2 = document.createElement("tr");
				var cell1 = document.createElement("td");
				var cell2 = document.createElement("td");
				var cell3 = document.createElement("td");
				var cell4 = document.createElement("td");
				var stat = document.createElement("img");
				if(markers[resp[i].name] && markers[resp[i].name].options.icon.iconUrl)
					stat.src = markers[resp[i].name].options.icon.iconUrl;
				cell1.setAttribute("rowspan", 2);
				cell1.appendChild(stat);
				cell2.setAttribute("rowspan", 2);
				cell2.appendChild(document.createElement("h3"));
				cell2.firstChild.appendChild(document.createTextNode(resp[i]["name"]));
				cell3.appendChild(document.createTextNode(resp[i]["address"]));
				cell4.appendChild(document.createTextNode(resp[i]["time"]));
				row1.appendChild(cell1);
				row1.appendChild(cell2);
				row2.appendChild(cell3);
				row1.appendChild(cell4);
				document.getElementById("clients_table").appendChild(row1);
				document.getElementById("clients_table").appendChild(row2);
			}
		}
	});
}