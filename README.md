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
* `/api/qualifications` - a list of qualifications. Takes `offset` and `limit` (do what you'd expect) as parameters.
* `/api/qualifications/:id` - more information about a qualification.
* `/api/boundaries` - a list of boundaries. Again takes `offset` and `limit`.
* `/api/exams` - a list of exams. Yet again takes `offset` and `limit`.

Frontend
--------
To come soon...
