Package.describe({
  summary: "A reactive model that builds structured JSON from PostgreSQL Records"
});

Package.on_use(function (api, where) {

  api.use([
    'postgresql',
    'npm',
    'bookshelf'
  ], ['server']);

  api.use([
    'underscore',
    'coffeescript',
    'mixen'
  ], ['client', 'server']);

  api.add_files(['model.coffee'], ['client', 'server']);

  api.export(['Model'],['client', 'server']);
});

Package.on_test(function (api) {
  api.use('module-model');
});
