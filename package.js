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

  api.add_files([
    'mixins/logs.coffee',
    'mixins/notifications.coffee',
    'mixins/allowRules.coffee',
    'mixins/persist.coffee'
  ], ['client', 'server']);

  api.add_files([
    'mediator.coffee',
    'model.coffee'
  ], ['client', 'server']);

  api.export([
    'Logs',
    'Notifications',
    'AllowRules',
    'Persist',
    'Mediator',
    'BookshelfModel',
    'Model',
    'BookshelfCollection',
    'Collection'
  ],['client', 'server']);
});

Package.on_test(function (api) {
  api.use('module-model');
});
