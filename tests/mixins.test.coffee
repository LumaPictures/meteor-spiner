if Meteor.isServer
  Tinytest.add "Mixins - Logs defined on server", (test) ->
    test.notEqual Logs, undefined, "Expected Logs to be defined on the server."

  Tinytest.add "Mixins - Mixen.Logs defined on server", (test) ->
    test.notEqual Mixen.Logs, undefined, "Expected Mixen.Logs to be defined on the server."

  Tinytest.add "Mixins - All defined on server", (test) ->
    test.notEqual All, undefined, "Expected All to be defined on the server."

  Tinytest.add "Mixins - Count defined on server", (test) ->
    test.notEqual Count, undefined, "Expected Count to be defined on the server."

  Tinytest.add "Mixins - Notifications defined on server", (test) ->
    test.notEqual Notifications, undefined, "Expected Notifications to be defined on the server."

  Tinytest.add "Mixins - AllowRules defined on server", (test) ->
    test.notEqual AllowRules, undefined, "Expected AllowRules to be defined on the server."

  Tinytest.add "Mixins - Persist defined on server", (test) ->
    test.notEqual Persist, undefined, "Expected Persist to be defined on the server."

if Meteor.isClient
  Tinytest.add "Mixins - Logs defined on client", (test) ->
    test.notEqual Logs, undefined, "Expected Logs to be defined on the client."

  Tinytest.add "Mixins - Mixen.Logs defined on client", (test) ->
    test.notEqual Mixen.Logs, undefined, "Expected Mixen.Logs to be defined on the client."

  Tinytest.add "Mixins - All defined on client", (test) ->
    test.notEqual All, undefined, "Expected All to be defined on the client."

  Tinytest.add "Mixins - Count defined on client", (test) ->
    test.notEqual Count, undefined, "Expected Count to be defined on the client."

  Tinytest.add "Mixins - Notifications defined on client", (test) ->
    test.notEqual Notifications, undefined, "Expected Notifications to be defined on the client."

  Tinytest.add "Mixins - AllowRules defined on client", (test) ->
    test.notEqual AllowRules, undefined, "Expected AllowRules to be defined on the client."

  Tinytest.add "Mixins - Persist defined on client", (test) ->
    test.notEqual Persist, undefined, "Expected Persist to be defined on the client."