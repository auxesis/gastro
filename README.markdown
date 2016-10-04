# Got Gastro

Got Gastro helps inform people about food safety problems when eating out or buying food.

## Using

Visit [gotgastroagain.com](https://gotgastroagain.com/).

![Visit gotgastroagain.com](https://c2.staticflickr.com/6/5150/30073568806_be226da539_z.jpg)

Tap to use your current location, or search for a location:

![Search location to find food safety problems around](https://c2.staticflickr.com/6/5759/30073568886_e2ea890431_z.jpg)

See the list of food safety problems around your search area:

![See the list of food safety problems](https://c2.staticflickr.com/6/5194/29993939462_394bfa695d_z.jpg)

Tap an entry to see details of the food safety problem:

![Tap to see details](https://c1.staticflickr.com/9/8393/29813271210_864c650fca_z.jpg)

### Data sources

Each state and territory publishes their data sets differently: from nothing, to HTML, to artisinally hand crafted PDFs for each breach.

NT, Tasmania, and Queensland don't publish their data.

| State | Format | URL | Scraper |
| ----- | ------ | :-- | ------- |
| New South Wales   | HTML   | http://foodauthority.nsw.gov.au/penalty-notices/ | https://morph.io/auxesis/nsw_food_authority_prosecution_notices and https://morph.io/auxesis/nsw_food_authority_penalty_notices |
| Victoria | HTML | https://www2.health.vic.gov.au/public-health/food-safety/convictions-register | https://morph.io/auxesis/vic_health_register_of_convictions |
| Queensland | nil |  |
| South Australia | HTML | http://www.sahealth.sa.gov.au/wps/wcm/connect/public+content/sa+health+internet/about+us/legislation/food+legislation/food+prosecution+register |
| Western Australia | PDF | http://ww2.health.wa.gov.au/Articles/F_I/Food-offenders/Publication-of-names-of-offenders-list |
| Tasmania | nil |  |
| Australian Capital Territory | PDF | http://www.health.act.gov.au/sites/default/files//Register%20of%20Food%20Offences.pdf |
| Northern Territory | nil |  |

## Developing

### Setup

Ensure you have Git, Ruby, and MySQL:

``` bash
git clone git@github.com:auxesis/gastro.git
cd gastro
bundle
rake db:setup
```

_MySQL is required due to OGC spatial analysis functions. In theory it should work with Postgres too, but is untested._

_The Rake tasks assume you have a root user with no password set_

### Running

Serve the app locally:

```
bundle exec foreman start -f Procfile.development
```

Then visit [http://localhost:9292/](http://localhost:9292/)

### Testing

Run the tests with:

```
bundle exec rake
```

## License

Got Gastro is MIT licensed.

