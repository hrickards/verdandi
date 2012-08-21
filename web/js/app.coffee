app = $.sammy ->
  @element_selector = '#app'
  @use 'Mustache', 'mustache'

  @get '#/home', (context) ->
    @app.swap ''
    @partial 'templates/home.mustache'

  @get '#/qualifications', (context) ->
    @load('http://localhost:3000/api/qualifications.json')
      .then (results) ->
        context.qualifications = _.map results.hits, (qualification) ->
          qualification.fields
        @load('templates/qualifications/qualification.mustache')
          .then (qualification_partial) ->
            context.partials =
              qualification: qualification_partial

            context.app.swap ''
            context.partial 'templates/qualifications/qualifications.mustache'

$ ->
  app.run '#/home'
