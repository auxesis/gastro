$(document).ready(function() {
  var x = document.getElementById("demo");

  function getLocation() {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(showPosition);
    } else {
      x.innerHTML = "Geolocation is not supported by this browser.";
    }
  }

  function showPosition(position) {
    x.innerHTML = "Latitude: " + position.coords.latitude +
    "<br>Longitude: " + position.coords.longitude;
  }

  $('button.geolocation').on('click', function() {
    getLocation()
  })

  $('div.results div.result').on('click', function() {
    var redirect = location.href.slice(0,-1) + '/detail'
    location.href = redirect
  })
})
