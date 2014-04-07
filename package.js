Package.describe({
  summary: "A reactive model that builds structured JSON from PostgreSQL Records"
});

Package.on_use(function (api, where) {
  Npm.depends({
    // [node-postgres connector](https://github.com/brianc/node-postgres)
    pg: '2.11.1',
    // [SQL ORM based on Backbone](http://bookshelfjs.org)
    bookshelf: '0.6.8'
  });

  api.use([
    'underscore',
    'coffeescript',
    'mixen'
  ], ['client', 'server']);

  api.use([
    'postgresql',
    'npm',
    'bookshelf'
  ], ['server']);

  api.add_files([
    'mixins/logs.coffee',
    'mixins/all.coffee',
    'mixins/count.coffee',
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
    'All',
    'Count',
    'Notifications',
    'AllowRules',
    'Persist',
    'Mediator',
    'BookshelfModel',
    'Model',
    'BookshelfCollection',
    'Collection'
  ], ['client', 'server']);
});

Package.on_test(function (api) {
  api.use('module-model');
});
