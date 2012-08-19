express       = require 'express'
path          = require 'path'
models        = require './models.coffee'

Qualification = models.Qualification
Boundary      = models.Boundary
Exam          = models.Exam


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
  offset = if request.query["offset"]? then request.query["offset"] else 0
  limit = if request.query["limit"]? then request.query["limit"] else 5
  Qualification.find {}, 'subject qualification awarding_body base', { skip: offset, limit: limit }, (error, qualifications) ->
    response.send qualifications

app.get '/api/qualifications/:id', (request, response) ->
  Qualification.findById request.param('id'), (error, qualification) ->
    response.send qualification

app.get '/api/boundaries', (request, response) ->
  offset = if request.query["offset"]? then request.query["offset"] else 0
  limit = if request.query["limit"]? then request.query["limit"] else 5
  Boundary.find {}, null, { skip: offset, limit: limit }, (error, boundaries) ->
    response.send boundaries

app.get '/api/exams', (request, response) ->
  offset = if request.query["offset"]? then request.query["offset"] else 0
  limit = if request.query["limit"]? then request.query["limit"] else 5
  Exam.find {}, null, { skip: offset, limit: limit }, (error, exams) ->
    response.send exams


# -----------------------------------------------------------------------------
# App setup
# -----------------------------------------------------------------------------
app.listen 3000
