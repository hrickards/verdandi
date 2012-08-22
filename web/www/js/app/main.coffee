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

  class QualificationView extends Marionette.ItemView
    template: qualificationTemplate
    tagName: 'div'
    className: 'qualification'

  class QualificationsView extends Marionette.CompositeView
    template: qualificationsTemplate
    tagName: 'div'
    id: 'qualifications'
    itemView: QualificationView
    collection: new Qualifications([new Qualification({subject: 'foo'}), new Qualification({subject: 'barbaz'})])

  App.addInitializer (options) ->
    qualificationsView = new QualificationsView
    App.mainRegion.show qualificationsView

  $ ->
    App.start()
