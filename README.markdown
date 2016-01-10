# Gastro

Gastro helps inform people about food safety problems when eating out or buying food.

Gastro is currently a prototype.

## Setup

Ensure you have Git, Ruby:

``` bash
git clone git@github.com:auxesis/gastro.git
cd gastro
bundle
```

## Running

Serve the app locally:

```
foreman start -f Procfile.development
```

Then visit [http://localhost:4000/](http://localhost:4000/)

## License

Gastro is MIT licensed.


## Documentation

### Data sources

Each state and territory publishes their data sets differently, from HTML, to artisinally hand crafted PDFs for each breach. 

NT and Queensland don't publish their data. 

| State | Format | URL |
| ----- | ------ | :-- |
| New South Wales   | HTML   | http://foodauthority.nsw.gov.au/penalty-notices/ |
| Victoria | HTML | https://www2.health.vic.gov.au/public-health/food-safety/convictions-register |
| Queensland | nil |  |
| South Australia | HTML | http://www.sahealth.sa.gov.au/wps/wcm/connect/public+content/sa+health+internet/about+us/legislation/food+legislation/food+prosecution+register |
| Western Australia | PDF | http://ww2.health.wa.gov.au/Articles/F_I/Food-offenders/Publication-of-names-of-offenders-list |
| Tasmania | nil |  |
| Australian Capital Territory | PDF | http://www.health.act.gov.au/sites/default/files//Register%20of%20Food%20Offences.pdf |
| Northern Territory | nil |  |


### Personas

```
Name: Jane Baker
Age: 46
Role: Take away orderer
Demographic: Nurse, Married, family of 4
Goals: Order dinner for family
Technical: Tablet, desktop
```

```
Name: Mohammed al-Faiz
Age: 23
Role: Lunch shopper
Demographic: Labourer, Single
Goals: Report dodgy sandwich shop
Technical: Smart phone
```

### Scenarios

```
Scenario: Search for shop nearby
Scenario: Search for shop by address
Scenario: Share found breach
Scenario: Report breach
```