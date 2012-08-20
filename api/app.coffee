express              = require 'express'
ElasticSearchClient  = require 'elasticsearchclient'

serverOptions =
  host: 'localhost',
  port: 9200

elasticSearch = new ElasticSearchClient(serverOptions)

app = module.exports = express()


# -----------------------------------------------------------------
#  Configuration
#  Very much based upon/copied from gh:austintaylor/batman-express
# -----------------------------------------------------------------

app.configure ->
  app.use app.router

app.configure 'development', ->
  app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', ->
  app.use express.errorHandler()

# -----------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------
buildQuery = (request) ->
  from = request.query["from"]
  from = 0 unless from?

  size = request.query["size"]
  size = 10 unless size?

  fields = request.query["fields"]
  fields = [fields] if fields? and typeof(fields) == "string"

  query = request.query["query"]
  query = "*" unless query?

  search_query = {
    from           : from,
    size           : size,
    query          : {
      query_string : {
        query      : query
      }
    }
  }
  search_query["fields"] = fields if fields?

  search_query

elasticResponse = (request, response, index_name, type_name) ->
  query = buildQuery request

  elasticSearch.search(index_name, type_name, query).on('data', (data) ->
    data = JSON.parse(data)
    if data['error']
      response.send data
    else
      hits = data['hits']
      hits['hits'] = hits['hits'].map (hit) ->
        delete hit['_index']
        delete hit['_type']
        hit

      response.send hits
  ).on('done', ->
    return 0
  ).on('error', (error) ->
    response.send error
  ).exec()


# -----------------------------------------------------------------
# Routes
# -----------------------------------------------------------------

app.get '/api/qualifications', (request, response) ->
  elasticResponse request, response, 'qualifications', 'qualification'

app.get '/api/boundaries', (request, response) ->
  elasticResponse request, response, 'boundaries', 'boundary'

app.get '/api/exams', (request, response) ->
  elasticResponse request, response, 'exams', 'exam'


# -----------------------------------------------------------------
# App setup
# -----------------------------------------------------------------
app.listen 3000
