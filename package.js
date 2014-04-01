Package.describe({
  summary: "A reactive model that builds structured JSON from PostgreSQL Records"
});

Package.on_use(function (api, where) {
  Npm.depends({
    // [SQL ORM based on Backbone](http://bookshelfjs.org)
    bookshelf: '0.6.8'
  });

  api.use([
    'meteor-postgres'
  ], ['server']);

  api.use([
    'underscore',
    'coffeescript',
    'module-mediator'
  ], ['client', 'server']);

  api.add_files(['model.coffee'], ['client', 'server']);

  api.export(['Model'],['client', 'server']);
});

Package.on_test(function (api) {
  api.use('module-model');
});
