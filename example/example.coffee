Meteor.startup( ->
  # connect to postgres db with a user
  if Meteor.isServer
    pgConString = "postgres://localhost/austin"
  else pgConString = null

  # create a persistent connection with postgres to monitor notifications
  Mediator.initialize(pgConString)

  User.initialize()
  User.subscribe.all()
  User.subscribe.count()
)