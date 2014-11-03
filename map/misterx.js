var baseurl = "http://a.tile.openstreetmap.org";
//var baseurl = "http://a.tile.openstreetmap.fr/hot";

var map;
var mapExtent = ol.proj.transform([12.4677, 50.711, 12.5079, 50.729], "EPSG:4326", "EPSG:3857");
var mapCenter = [
	(mapExtent[0] + mapExtent[2]) / 2,
	(mapExtent[1] + mapExtent[3]) / 2,
];

function init() {
	map = new ol.Map({
		target: "map",
		layers: [
			new ol.layer.Tile({
				source: new ol.source.XYZ({
					urls: [
						baseurl + "/{z}/{x}/{y}.png",
						baseurl + "/{z}/{x}/{y}.png",
						baseurl + "/{z}/{x}/{y}.png",
					],
				}),
			}),
			new ol.layer.Image({
				source: new ol.source.ImageStatic({
					url: "http://daten.ec-hasslau.de/misterx/2014/spielfeld.png",
					imageExtent: mapExtent,
					imageSize: [1488, 1052],
				}),
			}),
			new ol.layer.Vector({
				source: new ol.source.KML({
					url: "positions.kml",
					projection: "EPSG:3857",
				}),
			}),
		],
		overlays: [
			new ol.FeatureOverlay(),
		],
		view: new ol.View({
			center: mapCenter,
			zoom: 15,
			//minZoom: 14,
			//maxZoom: 16,
		}),
	});
}
