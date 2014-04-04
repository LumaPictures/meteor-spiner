Meteor.startup( ->
  if Meteor.isServer
    # create a persistent connection with postgres to monitor notifications
    Mediator.initialize "postgres://localhost/austin"

)

Meteor.startup( ->
  Users = new @UserCollection()
  if Meteor.isServer
    # create a persistent connection with postgres to monitor notifications
    Users.publish_all()
    Users.publish_count()
  Users.subscribe_notifications()
  Users.subscribe_all()
  Users.subscribe_count()
)