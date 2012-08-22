define [
  'jquery',
  'underscore',
  'backbone',
  'marionette',
  'handlebars',
  'text!templates/qualifications_layout.handlebars',
  'text!templates/qualifications.handlebars',
  'text!templates/qualification.handlebars'
  'text!templates/qualifications_search.handlebars'
], ($, _, Backbone, Marionette, Handlebars, qualificationsLayoutTemplate, qualificationsTemplate, qualificationTemplate, qualificationsSearchTemplate) ->
  App = new Marionette.Application
  App.addRegions
    mainRegion: '#app'
    searchRegion: '#search'

  Backbone.Marionette.Renderer.render = (template, data) ->
    Handlebars.compile(template)(data)

  class Qualification extends Backbone.Model

  class Qualifications extends Backbone.Collection
    model: Qualification
    url: ->
      "http://localhost:3000/api/qualifications.json"
    parse: (resp) ->
      _.map resp.hits, (qualification) ->
        qualification.fields.id = qualification.id
        qualification.fields
    search: (query) ->
      @query = query
      @find()
    find: ->
      search_query =
        query: @query
      _.each search_query, (value, key) ->
        if (value == null || value == undefined || value == '')
          delete search_query[key]
      @fetch
        data: search_query
        processData: true
        success: => @trigger "change"

  class QualificationsLayout extends Marionette.Layout
    template: qualificationsLayoutTemplate
    regions:
      search: "#search"
      results: "#results"

  class QualificationView extends Marionette.ItemView
    template: qualificationTemplate
    tagName: 'div'
    className: 'qualification'

  class QualificationsView extends Marionette.CompositeView
    initialize: ->
      @collection = new Qualifications
      @collection.on 'change', => @render()
      App.vent.on 'search:entered', => @collection.search $('#search-box').val()
      @collection.find()
    template: qualificationsTemplate
    tagName: 'div'
    itemView: QualificationView

  class QualificationsSearchView extends Marionette.ItemView
    template: qualificationsSearchTemplate
    tagName: 'div'
    events:
      'input #search-box': 'search'
    search: -> App.vent.trigger 'search:entered'

  App.addInitializer (options) ->
    qualificationsLayout = new QualificationsLayout
    App.mainRegion.show qualificationsLayout

    qualificationsLayout.results.show new QualificationsView
    qualificationsLayout.search.show new QualificationsSearchView

  $ ->
    App.start()
