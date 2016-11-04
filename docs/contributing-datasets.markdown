# What the Got Gastro architecture looks like

 - Nested scrapers (scrape, geocoding)
 - gotgastro_scraper
 - The /reset function
 - How it interplays with email alerts

# Writing and publishing a scraper on Morph

 - Follow Morph tutorial

# Pulling the data into gotgastro_scraper

 - write your scraper
 - consume it from gotgastro_scraper
 - gotgastro_scraper triggers gotgastroagain.com/reset webhook
 - data is pulled

# What to do in your scraper, vs what to do in gotgastro_scraper

 - scrape the source
 - geocode the data
 - gotgastro_scraper: just pull data in

# What the Got Gastro architecture looks like

 - Nested scrapers (scrape, geocoding)
 - gotgastro_scraper
 - The /reset function
 - How it interplays with email alerts

# The PR process

 - Write your scraper
 - Run it on Morph
 - Fork `gotgastro_scraper`
 - Add a new data source
 - Submit a PR

# To geocode, or to not geocode

 - Geocode in the scraper
 - No geocoding happens in `gotgastro_scraper`

# When to normalise the data

 - Fixing up dates
 - Multiple addresses

# Handling complex HTML data

 - Convert it to Markdown
