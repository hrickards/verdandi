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
  'text!templates/qualification_detailed.handlebars'
], ($, _, Backbone, Marionette, Handlebars, qualificationsLayoutTemplate, qualificationsTemplate, qualificationTemplate, qualificationsSearchTemplate, qualificationDetailedTemplate) ->
  App = new Marionette.Application
  App.addRegions
    mainRegion: '#app'

  Marionette.Renderer.render = (template, data) ->
    Handlebars.compile(template)(data)

  Handlebars.registerHelper 'humanifyBoundaries', (boundaries) ->
    _.map(boundaries, (number, grade) ->
      if grade == "a_star"
        grade = "A*"
      else
        grade = grade.charAt(0).toUpperCase() + grade.slice(1)
      "#{grade}: #{number}"
    ).join ", "

  class Qualification extends Backbone.Model

  class Qualifications extends Backbone.Collection
    model: Qualification
    url: ->
      "http://localhost:3000/api/qualifications.json"
    parse: (resp) ->
      _.map resp.hits, (qualification) -> qualification.fields
    search: (query) ->
      @query = query
      @find()
    find: ->
      search_query =
        query: @query
      @fetch
        data: search_query
        processData: true
        success: => @trigger "change"

  class QualificationsLayout extends Marionette.Layout
    template: qualificationsLayoutTemplate
    regions:
      search: "#search"
      results: "#results"
      detailed: "#detailed"

  class QualificationView extends Marionette.ItemView
    template: qualificationTemplate
    tagName: 'div'
    className: 'qualification'
    render: ->
      super
      $(@el).data 'id', @model.id

  class QualificationsView extends Marionette.CompositeView
    initialize: ->
      @collection = new Qualifications
      @collection.on 'change', =>
        $('.qualification')[0].click() unless @itemClicked
        @render()
      App.vent.on 'qualification:searched', => @collection.search $('#search-box').val()
      @collection.find()
    events:
      'click .qualification': 'select'
    template: qualificationsTemplate
    tagName: 'div'
    itemView: QualificationView
    itemClicked: false
    select: (event) ->
      @itemClicked = true
      id = $(event.srcElement).data 'id'
      qualification =  _.first _.filter(@collection.models, (q) -> q.id == id)
      App.vent.trigger 'qualification:clicked', qualification

  class QualificationsSearchView extends Marionette.ItemView
    template: qualificationsSearchTemplate
    tagName: 'div'
    events:
      'input #search-box': 'search'
    search: -> App.vent.trigger 'qualification:searched'

  class QualificationDetailedView extends Marionette.ItemView
    initialize: ->
      App.vent.on 'qualification:clicked', (model) =>
        @model = model
        @render()
    template: qualificationDetailedTemplate
    tagName: 'div'

  App.addInitializer (options) ->
    qualificationsLayout = new QualificationsLayout
    App.mainRegion.show qualificationsLayout

    qualificationsLayout.results.show new QualificationsView
    qualificationsLayout.search.show new QualificationsSearchView
    qualificationsLayout.detailed.show new QualificationDetailedView

  $ ->
    App.start()
