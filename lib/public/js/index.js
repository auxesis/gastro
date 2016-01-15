$(document).ready(function() {
  function getLocation() {
    if (navigator.geolocation) {
      var spinner = '<i class="fa fa-spinner fa-pulse"></i>'
      $('button.geolocation').html(spinner)

      navigator.geolocation.getCurrentPosition(showPosition)
    } else {
      var error = "<i class='fa fa-ban fa-fw'></i> Not supported by your browser.";
      $('button.geolocation').html(error)
    }
  }

  function showPosition(position) {
    console.log(position)
    if (position.coords) {
      var coords  = { lat: position.coords.latitude, lng: position.coords.longitude },
          query   = jQuery.param(coords);
      window.location = window.location + 'search?' + query;
    } else {
      var error = "<i class='fa fa-bomb fa-fw'></i> Couldn't find your location.";
      $('button.geolocation').html(error);
    }
  }

  $('button.geolocation').on('click', function() {
    getLocation()
  })
})
