var refreshPositions = 20;
var areaBounds = [[50.71394, 12.475855], [50.728509, 12.502956]];

var map = null;
var markers = new Array();

// init after load
document.addEventListener("load", init, false);
document.addEventListener("DOMContentLoaded", init, false);
function init() {
	map = L.map("map").fitBounds(areaBounds);

	// map
	L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6IjZjNmRjNzk3ZmE2MTcwOTEwMGY0MzU3YjUzOWFmNWZhIn0.Y8bhBaUMqFiPrDRW9hieoQ', {
		maxZoom: 17,
		id: 'mapbox.streets'
	}).addTo(map);

	// overlay
	L.imageOverlay("http://daten.ec-hasslau.de/misterx/2014/spielfeld.png", imgBounds).addTo(map);

	// positions
	L.realtime({
		url: '../map/positions.geojson',
		type: 'json'
	}, {
		interval: refreshPositions * 1000,
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
			return markers[feature.properties.name].bindPopup(feature.properties.name);
		},
		onEachFeature: function (feature, layer) { layer.bindPopup(feature.properties.name); }
	}).addTo(map);
}