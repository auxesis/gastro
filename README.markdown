# Got Gastro

[Got Gastro](https://gotgastroagain.com) helps inform people about food safety problems when eating out or buying food.

## Using

![Visit gotgastroagain.com](https://c2.staticflickr.com/6/5150/30073568806_be226da539_z.jpg)

Tap to use your current location, or search for a location:

![Search location to find food safety problems around](https://c2.staticflickr.com/6/5759/30073568886_e2ea890431_z.jpg)

See the list of food safety problems around your search area:

![See the list of food safety problems](https://c2.staticflickr.com/6/5194/29993939462_394bfa695d_z.jpg)

Tap an entry to see details of the food safety problem:

![Tap to see details](https://c1.staticflickr.com/9/8393/29813271210_864c650fca_z.jpg)

### Data sources

Each state and territory publishes their data sets differently: from nothing, to HTML, to artisanally hand crafted PDFs for each breach.

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

### Metrics

Calls to `/metrics` will return information about how Got Gastro is currently running:

``` json
{
  "businesses": 2117,
  "offences": 4104,
  "imports": {
    "count": 270,
    "last_7_days_count": 5,
    "last_import": {
      "started_at": "2017-07-11T10:54:32.000+00:00",
      "finished_at": "2017-07-11T10:55:02.000+00:00",
      "duration": 30
    },
    "last_import_human": {
      "started_at": "15 hours and 51 minutes ago",
      "finished_at": "15 hours and 51 minutes ago",
      "duration": "30 seconds"
    }
  }
}}
```

- `businesses`, `offences`, and `imports.count` show counts of each of those data types.
- `imports.last_7_days_count` is the number of times imports have been done in the last 7 days.
- `imports.last_import.*` contains raw timestamps and numerical duration of the last import.
- `imports.last_import_human.*` contains human readable timestamps and the numerical duration of the last import.

If `imports.last_import.duration` is `-1`, this means a reset started and has not finished. This can indicate that a reset is currently running, or it has failed.

### Health checks

Calls to `/health_checks` will return information about Got Gastro's performance:

``` json
[
  {
    "type": "CheckImportsCountInLastWeek",
    "status": "ok",
    "message": "There were 5 imports in the last week: 2652, 2662, 2672, 2682, 2692"
  },
  {
    "type": "CheckLastImportStatus",
    "status": "ok",
    "message": "Last import (#2692, starting at 2017-07-11 10:54:32 +0000) ran for 30.0 seconds"
  }
]
```

- `CheckImportsCountInLastWeek` errors if there have been 0 imports in the last 7 days.
- `CheckLastImportStatus` errors if the last import failed.

## Developing

![CircleCI build status](https://circleci.com/gh/auxesis/gastro.png?circle-token=27a395741dc9cb515e2c74222f015b2ffc6c8e2f)

### Pipeline

Got Gastro is continuously deployed, using [using CircleCI](https://circleci.com/gh/auxesis/gastro).

Builds and deploys are controlled by `bin/cibuild.sh` and `bin/cideploy.sh`.

Got Gastro runs on [Pivotal Web Services](https://run.pivotal.io/).

### Setup

Ensure you have Git, Ruby, Node, MySQL, and Redis:

``` bash
git clone git@github.com:auxesis/gastro.git
cd gastro
bundle
rake db:create
npm install
```

Then add a `.env` file so the app can talk to Morph:

```
# Used to trigger an import by hitting /reset?token=where_is_the_pizza
GASTRO_RESET_TOKEN=where_is_the_pizza

# Used to fetch a dataset from Morph. Get your Morph API key from https://morph.io/settings
MORPH_API_KEY=covfefe
```

You can find an example configuration at `.env.example`.

#### MySQL

MySQL is required due to OGC spatial analysis functions. In theory it should work with Postgres too, but it is untested.

The `db:create` and `db:destroy` Rake tasks assume your MySQL root user with no password set.

#### Redis

Redis is required for queueing jobs. It's started by Foreman automatically with the commands below in [Running](#running).

Foreman assumes you have `redis-server` on your path.

### Running

Serve the app locally:

```
bundle exec foreman start -f Procfile.development
```

Then visit [http://localhost:9292/](http://localhost:9292/)

### Data

Got Gastro depends on data pulled in from Morph.

The [`gotgastro_scraper`](https://morph.io/auxesis/gotgastro_scraper) normalises data from all the dependent scrapers, converting it to a standard format that the Got Gastro app can consume.

The `gotgastro_scraper` uses the webhook functionality of Morph to trigger a data reset in the Got Gastro app whenever data is updated.

The update process looks like this:

1. Individual scrapers (like the [NSW Penalty Notices](https://morph.io/auxesis/nsw_food_authority_penalty_notices)) run once a day on Morph. These collect data from the various state registries.
2. The `gotgastro_scraper` runs once a day on Morph.
3. When the `gotgastro_scraper` finishes, it makes a call to https://gotgastroagain.com/reset with a `?token=secret` query parameter.
4. The Got Gastro app fetches the latest data from the `gotgastro_scraper`, and ingests it.

For this multi-step process to work, you need to set two environment variables:

 - `MORPH_API_KEY`, your API key on Morph, for the Got Gastro app to query the Morph API for the latest data.
 - `GASTRO_RESET_TOKEN`, a private token that the `/reset` URL needs to be called with, to trigger a reset. Calls to `/reset` without the `?token=` query parameter will return a with a HTTP status code of 404.

For local development, set the `MORPH_API_KEY` to your own Morph API key, and set `GASTRO_RESET_TOKEN` to something easy to remember like `wheresthepizza`.

```
MORPH_API_KEY='something' GASTRO_RESET_TOKEN=wheresthepizza bundle exec foreman start -f Procfile.development
```

Then, to trigger a data import:

```
curl http://localhost:9292/reset?token=wheresthepizza
```

### Assets

We minify CSS and JavaScript so they load faster for users:

```
rake assets
```

This is automatically run in development under Foreman.

### CDN

Setting the `CDN_BASE` environment variable will cause assets to be linked to a CDN:

```
export CDN_BASE=https://de2d8d398fngi.cloudfront.net
```

This significantly speeds up serving of JS, CSS, images, and fonts.

### Facebook

Setting the `FB_APP_ID` environment variable allows for better Facebook Open Graph integration:

```
export FB_APP_ID=17246080911111112
```

You can create a new Facebook app to get an app id.

### Mail

Mail in development is handled by [MailCatcher](https://mailcatcher.me/).

MailCatcher is automatically started when you run the app in development (through `Procfile.development`), and is accessible at [http://localhost:1080](http://localhost:1080).

Mail in production is handled by [SendGrid](https://sendgrid.com/).

To configure mail in production, sign up for a SendGrid account, then set the `SENDGRID_USERNAME` and `SENDGRID_PASSWORD` environment variables.

```
export SENDGRID_USERNAME=hello
export SENDGRID_PASSWORD=world
```

### APM

Application performance management is handled by New Relic.

To set a license key, set the `NEWRELIC_LICENSE_KEY` environment variable:

```
export NEWRELIC_LICENSE_KEY=b1946ac92492d2347c6235b4d2611184
```

### Testing

Run the tests with:

```
bundle exec rake
```

## License

Got Gastro is MIT licensed.
