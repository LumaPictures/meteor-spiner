if Meteor.isServer
  Tinytest.add "Mediator - defined on server", (test) ->
    test.notEqual Mediator, undefined, "Expected Mediator to be defined on the server."

if Meteor.isClient
  Tinytest.add "Mediator - defined on client", (test) ->
    test.notEqual Mediator, undefined, "Expected Mediator to be defined on the client."