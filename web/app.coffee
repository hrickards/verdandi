express       = require 'express'
path          = require 'path'
Qualification = require './qualification.coffee'

app = module.exports = express()


# -----------------------------------------------------------------------------
#  Configuration
#  Very much based upon/copied from gh:austintaylor/batman-express
# -----------------------------------------------------------------------------

app.configure ->
  app.use app.router

app.configure 'development', ->
  app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', ->
  app.use express.errorHandler()

# -----------------------------------------------------------------------------
# Routes
# -----------------------------------------------------------------------------

app.get '/api/qualifications', (request, response) ->
  Qualification.find {}, (error, qualifications) ->
    response.send qualifications

app.get '/api/qualifications/:id', (request, response) ->
  Qualification.findById request.param('id'), (error, qualification) ->
    response.send qualification

# -----------------------------------------------------------------------------
# App setup
# -----------------------------------------------------------------------------
app.listen 3000
