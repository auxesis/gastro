# Add datasets to Got Gastro

Got Gastro has a simple way to add additional datasets to display and alert on.

This guide shows you how to add new datasets, and describes some of the things you should be aware of when writing scrapers.

## The Got Gastro architecture is nested

Got Gastro is made up of several components that work together to scrape, geocode, normalise, display, and alert on new data.

![The Got Gastro architecture](architecture.png)

Let's work across the architecture diagram left-to-right.

### We scrape data from sources

Sources are data that is published by government authorities about food safety problems in a certain jurisdiction. Data can be published in a variety of formats.

### Scrapers run on Morph

[Morph](https://morph.io) is a simple platform for running scrapers and storing the resulting data.

Scrapers run once a day on Morph, and append data to the previous collection of records.

After scraping the data, the scrapers must geocode addresses.

Morph provides [excellent documentation](https://morph.io/documentation) on how to write scrapers and use the Morph platform.

### Data is normalised by `gotgastro_scraper`

Each scraper typically stores the data with columns that match the source data. For example, one data source may refer to a date as `offence_date`, while another names the column `date_of_offence`.

Got Gastro has a standard way of representing the data. [`gotgastro_scraper`](https://morph.io/auxesis/gotgastro_scraper) pulls data from the upstream scrapers, and maps the upstream fields into a standard format.

### `gotgastro_scraper` triggers a data import

When the `gotgastro_scraper` finishes, Morph calls a webhook at https://gotgastroagain.com/reset. This triggers a background job that fetches all the `gotgastro_scraper` data [from the Morph API](https://morph.io/documentation/api?scraper=auxesis%2Fgotgastro_scraper), and imports it into the Got Gastro database.

### Email alerts are sent after each data import

After a data import finishes, an EmailAlerts job is triggered. The job builds up a list of new offences that people have signed up to be alerted about, then sends out emails.

## Scrapers are unique to the data they're scraping

Each scraper is different, because each data source is different.

In the [best cases](https://health.data.ny.gov/Health/Food-Service-Establishment-Last-Inspection/cnih-y5dw), data is published via an API. This makes it easy to scrape, because the data is already represented in a computer readable format.

The next best data [is published as HTML in tables](http://foodauthority.nsw.gov.au/penalty-notices/default.aspx?template=results). Tables are pretty easy to scrape, because there's one row per key:value pair. This means you can write a [simple lookup table](https://github.com/auxesis/nsw_food_authority_penalty_notices/blob/9a06d302b5e1fa3d17925abc3324c14d392941f4/scraper.rb#L9-L22) and [build up a data dictionary](https://github.com/auxesis/nsw_food_authority_penalty_notices/blob/9a06d302b5e1fa3d17925abc3324c14d392941f4/scraper.rb#L34-L53) by looking up row labels in the lookup table.

Some data is published as [semi-structured HTML](http://www.sahealth.sa.gov.au/wps/wcm/connect/public+content/sa+health+internet/about+us/legislation/food+legislation/food+prosecution+register) from a WYSIWYG editor. This is [painful to scrape](https://github.com/auxesis/sa_health_food_prosecutions_register), because each entry ends up being a special snowflake. The good news is that artisanal, hand-crafted data sets like these tend to have few entries.

Other data is [published as PDFs](http://ww2.health.wa.gov.au/Articles/F_I/Food-offenders/Publication-of-names-of-offenders-list), with a PDF per notice. This requires [writing a scraper](https://github.com/disclosurelogs/au-wa-food-offenses) that downloads and extracts values out of the PDF.

In the worst cases, data is published as a PDF, but with a [single PDF for all notices](http://www.health.act.gov.au/sites/default/files//Register%20of%20Food%20Offences.pdf).

## Scrapers must geocode addresses

You must geocode the data in the upstream scrapers.

`gotgastro_scraper` does not perform any geocoding. It expects the data it consumes has already been geocoded.

If you want to plug in [a scraper that doesn't geocode its addresses](https://github.com/disclosurelogs/au-wa-food-offenses) to `gotgastro_scraper`, you can write a [second scraper](https://github.com/auxesis/wa_health_food_offenders) that wraps it, geocodes addresses, and republishes the data.

Plug that data into the `gotgastro_scraper`, and you're good to go.

# Pulling the data into gotgastro_scraper

 - write your scraper
 - consume it from gotgastro_scraper
 - gotgastro_scraper triggers gotgastroagain.com/reset webhook
 - data is pulled

# What to do in your scraper, vs what to do in gotgastro_scraper

 - scrape the source
 - geocode the data
 - gotgastro_scraper: just pull data in

# The PR process

 - Write your scraper
 - Run it on Morph
 - Fork `gotgastro_scraper`
 - Add a new data source
 - Submit a PR

# When to normalise the data

 - Fixing up dates
 - Multiple addresses

# Handling complex HTML data

 - Convert it to Markdown
