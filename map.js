const map = L.map('map').setView([39.50, -98.35], 5);

L.tileLayer('https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png', {
	attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
}).addTo(map);

const xhr = new XMLHttpRequest();
xhr.open('GET', './data/counties_and_cases.geojson');
xhr.setRequestHeader('Content-Type', 'application/json');
xhr.responseType = 'json';
xhr.onload = function() {
    if (xhr.status !== 200) return
    
    const getColor = function(d) {
      const mapScale = chroma.scale(['#FFEDA0', '#800026']).domain([0, 9000]);
      return mapScale(d)
    }
    
    const style = function(date, feature) {
      return {
        fillColor: getColor(feature.properties[date]),
        weight: 1,
        opacity: 1,
        color: 'white',
        fillOpacity: 0.7
      };
    }
    
    counties = L.geoJSON(xhr.response, {style: style.bind(null, dates.slice(-1)[0])}).addTo(map);
    
    const slider = document.createElement("input");
    slider.setAttribute("id", "slider");
    slider.setAttribute("type", "range");
    slider.setAttribute("min", 0);
    slider.setAttribute("max", dates.length-1);
    slider.value = dates.length-1;
    
    const sliderText = document.getElementById("sliderText");
    sliderText.innerHTML = dates[slider.value];
    
    slider.oninput = function() {
      sliderText.innerHTML = dates[this.value];
      counties.setStyle(style.bind(null, dates[this.value]));
    }
    
    const sliderContainer = document.getElementById("sliderContainer");
    sliderContainer.appendChild(slider);
};
xhr.send();
