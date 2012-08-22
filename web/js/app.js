requirejs.config({
  baseUrl: '/',
  paths: {
    app             : 'js/app',
    jquery          : 'js/lib/jquery',
    underscore      : 'js/lib/underscore',
    backbone        : 'js/lib/backbone',
    marionette      : 'js/lib/backbone.marionette',
    handlebars      : 'js/lib/handlebars',
    cs              : 'js/lib/cs',
    'coffee-script' : 'js/lib/coffee-script',
    text            : 'js/lib/text'
  },
  shim: {
    marionette: {
      deps: ['backbone'],
      exports: 'Backbone.Marionette'
    },
    backbone: {
      deps: ["underscore", "jquery"],
      exports: 'Backbone'
    },
    handlebars: {
      deps: [],
      exports: 'Handlebars'
    }
  }
});

requirejs(['cs!app/main']);
