if Meteor.isServer
  Tinytest.add "Collection - Collection defined on server", (test) ->
    test.notEqual Collection, undefined, "Expected Collection to be defined on the server."

  Tinytest.add "Collection - Mixen.Collection defined on server", (test) ->
    test.notEqual Mixen.Collection, undefined, "Expected Mixen.Collection to be defined on the server."

if Meteor.isClient
  Tinytest.add "Collection - Collection defined on client", (test) ->
    test.notEqual Collection, undefined, "Expected Collection to be defined on the client."

  Tinytest.add "Collection - Mixen.Collection defined on client", (test) ->
    test.notEqual Mixen.Collection, undefined, "Expected Mixen.Collection to be defined on the client."