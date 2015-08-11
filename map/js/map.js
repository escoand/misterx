var refreshInterval = 20;
var imgBounds = [[50.711, 12.4677], [50.729, 12.5079]];

var map = null;
var markers = Array();

// init after load
document.addEventListener("load", init, false);
document.addEventListener("DOMContentLoaded", init, false);
function init() {
	map = L.map("map").fitBounds(imgBounds);

	// map
	L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6IjZjNmRjNzk3ZmE2MTcwOTEwMGY0MzU3YjUzOWFmNWZhIn0.Y8bhBaUMqFiPrDRW9hieoQ', {
		maxZoom: 17,
		id: 'mapbox.streets'
	}).addTo(map);

	// overlay
	L.imageOverlay("http://daten.ec-hasslau.de/misterx/2014/spielfeld.png", imgBounds).addTo(map);

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
}