# a subscription and publication mixin for all data in a collection
class All
  # On the client listen to changes in the all_<model.tableName> publication
  subscribe_all: ->
    self = @
    if Meteor.isClient
      Meteor.subscribe "all_#{self.getTableName()}"


  publish_all: ->
    self = @
    if Meteor.isClient
      self.error "Data can only be published from the server."
    if Meteor.isServer
      Meteor.publish "all_#{self.getTableName()}", -> self.meteorCollection.find()