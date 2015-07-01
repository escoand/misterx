var refreshIntervalAdmin = 10;

function initAdmin() {
	refreshAdmin();

	/* init refresh */
	window.setInterval("refreshAdmin()", refreshIntervalAdmin * 1000);
}

function refreshAdmin() {
	$.getJSON("status", function(data) {

		// clear
		while(map.getLayers().getLength() > 3)
			map.removeLayer(map.getLayers().getArray()[3]);
		var elems = document.getElementById("clients").getElementsByTagName("tr");
		while(elems.length > 1)
			document.getElementById("clients").removeChild(elems[1]);

		// request status
		for(var i = 0; i < data.length; i++) {
			var row = document.createElement("tr");
			var cell1 = document.createElement("td");
			var cell2 = document.createElement("td");
			var cell3 = document.createElement("td");
			var cell4 = document.createElement("td");
			var stat = document.createElement("img");
			stat.src = "img/" + data[i]["status"] + ".png";
			//stat.alt = data[i]["status"];
			cell1.appendChild(stat);
			cell2.appendChild(document.createTextNode(data[i]["name"]));
			cell3.appendChild(document.createTextNode(data[i]["address"]));
			cell4.appendChild(document.createTextNode(data[i]["time"]));
			row.appendChild(cell1);
			row.appendChild(cell2);
			row.appendChild(cell3);
			row.appendChild(cell4);
			document.getElementById("clients").appendChild(row);
		}
	});
}

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

// submit position
function submit() {
	$.getJSON("position", {
		admin:	true,
		id:	document.getElementById("misterx").value,
		gprmc:	document.getElementById("data").value
	},
		function() {
		if(this.readyState==4 && this.status==200)
			document.getElementById("popup").style.display = "none";
		else if(this.readyState==4)
			alert(this.status + " " + this.statusText);
	});
}


/* init after load */
document.addEventListener("load", initAdmin, false);
document.addEventListener("DOMContentLoaded", initAdmin, false);