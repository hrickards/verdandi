// For any third party dependencies, like jQuery, place them in the lib folder.

// Configure loading modules from the lib directory,
// except for 'app' ones, which are in a sibling
// directory.
requirejs.config({
  //baseUrl: 'js/lib',
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

// Start loading the main app file. Put all of
// your application logic in there.
requirejs(['cs!app/main']);
