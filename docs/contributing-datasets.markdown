# Contribute datasets to Got Gastro

Got Gastro has a simple way to add additional datasets to display and alert on.

This guide shows you how to add new datasets, and describes some of the things you should be aware of when writing scrapers.

## The Got Gastro architecture is nested

Got Gastro is made up of several components that work together to scrape, geocode, normalise, display, and alert on new data.

![The Got Gastro architecture](architecture.png)

Let's work across the architecture diagram left-to-right.

### Data is scraped from sources

Sources are data that is published by government authorities about food safety problems in a certain jurisdiction. Data can be published in a variety of formats, some harder to scrape than others.

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

## Create a PR on `gotgastro_scraper` when you want to add a dataset

To get a new data source added to Got Gastro, follow these steps:

1. Write your scraper
1. Run it on Morph
1. Fork [`gotgastro_scraper`](https://github.com/auxesis/gotgastro_scraper)
1. Add a new data source
1. Submit a PR back to `gotgastro_scraper` with your changes

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

Sometimes when geocoding addresses, the API returns the wrong location. Consider setting a bounding box for the jurisdiction you're dealing with data from, and check if the lat/lng returned by your geocoding API falls within the bounding box.

If it doesn't, consider appending more specific information to the address, like postcode, town, state, or country.

## Try to normalise the data in your scraper

Because data comes from humans, it is weird, inconsistent, and beautiful. There's something fun about writing scrapers that bring order to the chaos of data published by government.

The biggest challenges you'll have when writing scrapers for food safety data are:

 - Making dates consistent
 - Multiple addresses for a single offence, and
 - Detailed offence information that is HTML formatted

### Format dates as ISO8601 YYYY-MM-DD

Date handling can be made pretty straightforward – get the data into an [ISO8601](https://en.wikipedia.org/wiki/ISO_8601#Calendar_dates) format like `YYYY-MM-DD`. If you're writing scrapers in Ruby, you can lean on [`Date#parse`](https://ruby-doc.org/stdlib-2.1.1/libdoc/date/rdoc/Date.html#method-c-parse) and [Chronic](https://github.com/mojombo/chronic) to do a lot of the heavy lifting for you.

### Drop an address, or split out to multiple business entries

Multiple addresses for a single offence can be tricky. Sometimes offences are issued for businesses that have multiple places of business. For example, a business may have a shopfront and a storage facility. The authority that issues food safety warnings in that business's jurisdiction may issue a notice that lists both places.

Got Gastro doesn't currently support multiple addresses, so you have to either pick one (and drop the other), or create multiple businesses for a single offence. If you choose to drop one of the addresses, make sure it's the one that people are _less likely_ to visit.

### Convert HTML to Markdown

Big food safety problems often include a lot of a information. If the business has been taken to court, food authorities often publish very detailed information about the food safety problems the business was successfully prosecuted for. This can include [specific references to legislation](https://gotgastroagain.com/business/26aafb642171582cb7a2052419a75000) that was breached.

If you scrape data like this, you should convert it to [Markdown](https://en.wikipedia.org/wiki/Markdown). Markdown is a useful intermediary format that can be easily converted to HTML and other formats.

If you're writing scrapers in Ruby, the [`reverse_markdown`](https://github.com/xijo/reverse_markdown) gem is very useful for converting HTML to Markdown.

## Modify `gotgastro_scraper` to get your data into a format Got Gastro can understand

Once you've written your scraper, you'll need to modify [`gotgastro_scraper`](https://github.com/auxesis/gotgastro_scraper) to get the data into a format Got Gastro understands.

Check out [`scraper.rb`](https://github.com/auxesis/gotgastro_scraper/blob/master/scraper.rb) to see how other scrapers have their data pulled.

A scraper needs to expose `fetch`, `businesses`, and `offences` methods. The scraper will call these methods when doing a run

``` ruby
class Jurisdiction
  def fetch
    # Fetch data from a scraper on Morph via Morph's API.
    # Build a list of @records that can be used by `businesses` and `offences`
  end

  def businesses
    # `businesses` returns an Array of Hashes, in the following format:
    [
      {
        'id'      => ..., # primary key, String, must be unique
        'name'    => ..., # String, the trading name of the business
        'address' => ..., # String, the displayable address of the business
        'lat'     => ..., # Float, the latitude of the address
        'lng'     => ..., # Float, the longitude of the address
      }
    ]
  end

  def offences
    # `offences` returns an Array of Hashes, in the following format:
    [
      {
        'link'        => ..., # primary key, String, URL to the offence, must be unique
        'business_id' => ..., # foreign key, String, must match to a business.id
        'date'        => ..., # Date, date of the offence
        'description' => ..., # String, description of the offence
        'severity'    => 'major', # String, must be one of `major` or `minor`
      }
    ]
  end
end
```

When the `gotgastro_scraper` is run, it saves the aggregated data into two tables: [`businesses`](https://morph.io/auxesis/gotgastro_scraper#table_businesses), and [`offences`](https://morph.io/auxesis/gotgastro_scraper#table_offences).

This data is then queried by Got Gastro's Import worker, [via Morph's API](https://morph.io/documentation/api?scraper=auxesis%2Fgotgastro_scraper),

Once you've written your scraper, [submit a PR](https://github.com/auxesis/gotgastro_scraper/compare) to get your changes merged.
