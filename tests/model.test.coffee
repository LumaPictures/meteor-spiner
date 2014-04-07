if Meteor.isServer
  Tinytest.add "Model - BookshelfModel defined on server", (test) ->
    test.notEqual BookshelfModel, undefined, "Expected BookshelfModel to be defined on the server."

  Tinytest.add "Model - Model defined on server", (test) ->
    test.notEqual Model, undefined, "Expected Model to be defined on the server."

  Tinytest.add "Model - Mixen.Model defined on server", (test) ->
    test.notEqual Mixen.Model, undefined, "Expected Mixen.Model to be defined on the server."

if Meteor.isClient
  Tinytest.add "Model - BookshelfModel undefined on client", (test) ->
    BookshelfModel = BookshelfModel or undefined
    test.equal BookshelfModel, undefined, "Expected BookshelfModel to be undefined on the client."

  Tinytest.add "Model - Model defined on client", (test) ->
    test.notEqual Model, undefined, "Expected Model to be defined on the client."

  Tinytest.add "Model - Mixen.Model defined on server", (test) ->
    test.notEqual Mixen.Model, undefined, "Expected Mixen.Model to be defined on the client."