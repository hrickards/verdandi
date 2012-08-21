Verdandi
=======

Exam details, grade boundaries and various related things.
Vaguely based upon my Rewired State nhtg12 project (`gh:hrickards/nhtg12`)

Scraping Data
-------------
`cd` into `scraper` and run `rake`. For more customised scraping, take a look at `Rakefile`.

API
---
A pretty simple node app in `api`, which can be run with `node server.js`.
Currently consists of the following endpoints (all GET):
* `/api/qualifications.json` - a list of qualifications/specifications.
* `/api/boundaries.json` - a list of boundaries for all units.
* `/api/exams.json` - a list of exams for all units.

All three endpoints can be filtered by passing in the following parameters:
* `from` - a number to offset all results by (for pagination). Defaults to 0.
* `size` - the number of results to return. Defaults to 10.
* `fields` - comma separated list of fields to return. Defaults to all fields.
* `query` - a string to search for, using ElasticSearch syntax.

Frontend
--------
To come soon...
