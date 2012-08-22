define [
  'jquery',
  'underscore',
  'backbone',
  'marionette',
  'handlebars',
  'text!templates/qualifications.handlebars',
  'text!templates/qualification.handlebars'
], ($, _, Backbone, Marionette, Handlebars, qualificationsTemplate, qualificationTemplate) ->
  App = new Marionette.Application
  App.addRegions
    mainRegion: '#app'

  Backbone.Marionette.Renderer.render = (template, data) ->
    Handlebars.compile(template)(data)

  class Qualification extends Backbone.Model

  class Qualifications extends Backbone.Collection
    model: Qualification
    url: ->
      "http://localhost:3000/api/qualifications.json?query=#{@query}"
    parse: (resp) ->
      _.map resp.hits, (qualification) ->
        qualification.fields.id = qualification.id
        qualification.fields
    search: (query) ->
      @query = query
      @fetch
        success: =>
          @trigger "change"

  class QualificationView extends Marionette.ItemView
    template: qualificationTemplate
    tagName: 'div'
    className: 'qualification'

  class QualificationsView extends Marionette.CompositeView
    initialize: ->
      @collection = new Qualifications
      @collection.on 'change', =>
        @render()

      @collection.search 'Physics'

    template: qualificationsTemplate
    tagName: 'div'
    id: 'qualifications'
    itemView: QualificationView

  App.addInitializer (options) ->
    qualificationsView = new QualificationsView
    App.mainRegion.show qualificationsView

  $ ->
    App.start()
