$(document).ready(function() {
  $('div.results div.result').on('click', function(e, el) {
    var redirect = $(this).find('h4 a')[0].href
    location.href = redirect
  })
})
