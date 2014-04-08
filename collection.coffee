class Collection
  # create collection with all its mixins and setup for app
  initialize: ( models, options ) ->
    self = @
    # create a new Mediator for this collection
    # Mediator is a singleton Class that returns the same instance after initial initialization
    # Mediator listens to PostgreSQL notifications on channels specified by the objects using the Mediator
    # Mediator reactively publishes notifications to the correct objects based on their subscriptions
    self.mediator = Mediator.initialize()
    if Meteor.isServer
      # set the allow rules for this collection
      self.setAllowRules()
      # make sure the PostgreSQL and MongoDB are in sync
      self.syncronize_collection()
    self.log "#{ self.model.getTableName() }:collection:initialized"

  # return the table name of the associated model
  getTableName: ->
    self = @
    self.model.getTableName()

  # access to the relatedTables model instance property
  getRelatedTables: ->
    self = @
    self.model.getRelatedTables()

  # access to the schema model instance property
  getSchema: ->
    self = @
    self.model.getSchema()

  # set the method to run for each collection operation
  # each method returns true or false
  # true allows the operation to proceed to MongoDB
  # false stops the operation and rolls back the client mini-mongo collection
  allow: ->
    self = @
    return {
      # on client insert create a postgreSQL record, then write the joined document to MongoDB
      insert: self.persist_create.bind( self )
      # on client document update
      # update the corresponding PostgreSQL record
      # create a new joined document and upsert to MongoDB
      update: self.persist_update.bind( self )
      # on client delete
      # remove the postgreSQL record
      # archive the MongoDB record
      remove: self.persist_remove.bind( self )
    }

# Create a base Collection Mixen alias
Mixen.Collection = ( modules... ) ->
  if Meteor.isServer
    return Mixen modules..., AllowRules, Notifications, Persist, Count, All, Collection, Mixen.Logs(), BookshelfCollection
  if Meteor.isClient
    return Mixen modules..., AllowRules, Notifications, Persist, Count, All, Collection, Mixen.Logs()