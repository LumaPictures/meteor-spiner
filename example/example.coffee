###### Initialization
# only define pgConString on the server for security
if Meteor.isServer
  # pgContstring format is `postgres://<host>/<user>
  pgConString = "postgres://localhost/austin"
else pgConString = null

# create a persistent connection with postgres to monitor notifications
# on the client mediator does not connect to postgres
# however mediator and still pub / sub intra app notifications on the client
Mediator.initialize pgConString

@Users = new UserCollection()
if Meteor.isServer
  # create a persistent connection with postgres to monitor notifications
  Users.publish_all()
  Users.publish_count()
Users.subscribe_notifications()
Users.subscribe_all()
Users.subscribe_count()

###### Views
if Meteor.isClient
  Template.users.count = ->
    return Session.get "#{ Users.getTableName() }_count"

  Template.users.users = ->
    return Users.meteorCollection.find()