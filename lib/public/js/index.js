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
  }

  $('button.geolocation').on('click', function() {
    getLocation()
  })
})
