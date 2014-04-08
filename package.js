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
    'mixins/logs.mixin.coffee',
    'mixins/all.mixin.coffee',
    'mixins/count.mixin.coffee',
    'mixins/notifications.mixin.coffee',
    'mixins/allowRules.mixin.coffee',
    'mixins/persist.mixin.coffee'
  ], ['client', 'server']);

  api.add_files([
    'mediator.coffee',
    'bookshelf.coffee',
    'model.coffee',
    'collection.coffee'
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
  api.use([
    'coffeescript',
    'postgresql',
    'npm',
    'module-model',
    'tinytest',
    'test-helpers'
  ], ['client', 'server']);

  api.add_files([
    'tests/mediator.test.coffee',
    'tests/bookshelf.test.coffee',
    'tests/mixins.test.coffee',
    'tests/model.test.coffee',
    'tests/collection.test.coffee'
  ], ['client', 'server']);
});
