if Meteor.isServer
  Tinytest.add "Bookshelf - BookshelfModel defined on server", (test) ->
    test.notEqual BookshelfModel, undefined, "Expected BookshelfModel to be defined on the server."

  Tinytest.add "Bookshelf - BookshelfCollection defined on server", (test) ->
    test.notEqual BookshelfCollection, undefined, "Expected BookshelfCollection to be defined on the server."

if Meteor.isClient
  Tinytest.add "Bookshelf - BookshelfModel undefined on client", (test) ->
    BookshelfModel = BookshelfModel or undefined
    test.equal BookshelfModel, undefined, "Expected BookshelfModel to be undefined on the client."

  Tinytest.add "Bookshelf - BookshelfCollection undefined on client", (test) ->
    BookshelfCollection = BookshelfCollection or undefined
    test.equal BookshelfCollection, undefined, "Expected BookshelfCollection to be undefined on the client."