var dataUrl = "positions.geojson";
var refreshInterval = 30;

var map;
var popup;
var styleId = 0;

var styleFunction = function(feature, resolution) {

	/* set style */
	if(!feature.get("style"))
		feature.set("style", ++styleId);

	/* add point at last position */
	if(feature.getGeometry().getLastCoordinate) {
		feature.setGeometry(new ol.geom.GeometryCollection([
			feature.getGeometry(),
			new ol.geom.Point(feature.getGeometry().getLastCoordinate()),
		]));
	}

	return [new ol.style.Style({
		image: new ol.style.Icon({
			anchor: [0.5, 1],
			src: icons[feature.get("style")],
		}),
		stroke: new ol.style.Stroke({
			color: colors[feature.get("style")],
			width: 2,
		}),
	})]
};

function init(){
	popup = document.getElementById("popup");

	map = new ol.Map({
		target: "map",
		controls: [
			new ol.control.Zoom()
		],
		layers: [
			new ol.layer.Tile({
				source: new ol.source.OSM(),
			}),
			new ol.layer.Vector({
				source: new ol.source.Vector({
					url: dataUrl,
					format: new ol.format.GeoJSON()
				}),
				style: styleFunction,
			}),
		],
		overlays: [
			new ol.Overlay({
				element: popup,
				positioning: 'bottom-center',
				stopEvent: false
			})
		],
		view: new ol.View({
			center: ol.proj.transform([-73.7, 47.9], 'EPSG:4326', 'EPSG:3857'),
			zoom: 10
		})
	});

	/* click callbacks */
	map.on('click', function(evt) {
		var feature = map.forEachFeatureAtPixel(evt.pixel,
			function(feature, layer) {
				return feature;
		});
		if (feature && feature.getGeometry() instanceof ol.geom.GeometryCollection) {
			var coord = feature.getGeometry().getGeometries()[1].getCoordinates();
			map.getOverlays().getArray()[0].setPosition(coord);
			$(popup).popover({
				"placement": "right",
				"content": feature.get("name")
			});
			$(popup).popover("show");
		} else {
			$(popup).popover("destroy");
		}
	});

	/* init refresh */
	window.setInterval("refresh()", refreshInterval * 1000);
}

/* refresh positions */
function refresh() {
	styleId = 0;
	map.getLayers().getArray()[1].setSource(
		new ol.source.Vector({
			url: dataUrl,
			format: new ol.format.GeoJSON()
		})
	);
}

/* init after load */
document.addEventListener("load", init, false);
document.addEventListener("DOMContentLoaded", init, false);