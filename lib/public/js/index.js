function initAutocomplete() {
  // Create the autocomplete object, restricting the search to geographical
  // location types.
  autocomplete = new google.maps.places.Autocomplete(
      (document.getElementById('autocomplete')),
      {types: ['geocode']});

  // When the user selects an address from the dropdown, populate the address
  // fields in the form.
  autocomplete.addListener('place_changed', searchFromAddress);
}

function searchFromAddress() {
  var place = autocomplete.getPlace();
  var coords  = { lat: place.geometry.location.lat(), lng: place.geometry.location.lng() },
      query   = jQuery.param(coords);
  window.location = window.location + 'search?' + query;
}

function geolocate() {
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(function(position) {
      var geolocation = {
        lat: position.coords.latitude,
        lng: position.coords.longitude
      };
      var circle = new google.maps.Circle({
        center: geolocation,
        radius: position.coords.accuracy
      });
      autocomplete.setBounds(circle.getBounds());
    });
  }
}

$(document).ready(function() {
  function getLocation() {
    if (navigator.geolocation) {
      var spinner = '<i class="fa fa-spinner fa-pulse"></i>'
      $('button.geolocation').html(spinner)

      navigator.geolocation.getCurrentPosition(showPosition, showError)
    } else {
      var error = "<i class='fa fa-ban fa-fw'></i> Not supported by your browser.";
      $('button.geolocation').html(error)
    }
  }

  function showPosition(position) {
    if (position.coords) {
      var coords  = { lat: position.coords.latitude, lng: position.coords.longitude },
          query   = jQuery.param(coords);
      window.location = window.location + 'search?' + query;
    } else {
      var error = "<i class='fa fa-bomb fa-fw'></i> Couldn't find your location.";
      $('button.geolocation').html(error);
    }
  }

  function showError(error) {
    switch(error.code) {
      case error.PERMISSION_DENIED:
        var error = "<i class='fa fa-bomb fa-fw'></i> Browser denied location lookup.";
        break;
      case error.POSITION_UNAVAILABLE:
        var error = "<i class='fa fa-bomb fa-fw'></i> Location information is unavailable.";
        break;
      case error.TIMEOUT:
        var error = "<i class='fa fa-bomb fa-fw'></i> Timeout when looking up location.";
        break;
      case error.UNKNOWN_ERROR:
        var error = "<i class='fa fa-bomb fa-fw'></i> Unknown error :-(";
        break;
    }
    $('button.geolocation').html(error);
  }

  $('button.geolocation').on('click', function() {
    getLocation()
  })

})
