if Meteor.isServer
  # PostgreSQL connection credentials
  # TODO : provide con creds through environment variables
  PostgreSQL =
    client: 'pg'
    connection:
      host: 'localhost'
      user: 'austin'

  # manually include Bookshelf prior to startup
  Bookshelf = Npm.require 'bookshelf'

  # ensure that Bookshelf can only be initialized once
  Bookshelf.initialize = _.once Bookshelf.initialize

  # Initialize PostgreSQL connection and create client pool for Bookshelf
  Bookshelf.PostgreSQL = Bookshelf.initialize PostgreSQL

  # wrap Bookshelf to provide syncronous db query methods
  class BookshelfModel extends Bookshelf.PostgreSQL.Model
    # wraps the async save method in a fiber
    saveSync: ( doc ) ->
      self = @
      if Meteor.isClient
        self.error "BookshelfModel.saveSync() can only be called on the server."
      if Meteor.isServer
        # Async is provided by arunoda's awesome `npm` package
        # runSync blocks this fiber until execution is complete
        Async.runSync ( done ) ->
          self.save _.pick( doc, self.schema )
          # Once the model is saved return the fiber
          .then ( result, error ) ->
            if error
              self.error "persist:create:#{ doc._id }:error", error
            done error, result

    # wraps the asyncronous fetch method to run in a syncronous fiber
    fetchSync: ( options ) ->
      self = @
      if Meteor.isClient
        self.error "BookshelfModel.fetchSync() can only be called on the server."
      if Meteor.isServer
        # Async is provided by arunoda's awesome `npm` package
        # runSync blocks this fiber until execution is complete
        Async.runSync ( done ) ->
          # call the original Bookshelf.fetch method
          self.fetch( options )
          # terminate the fiber when Bookshelf.fetch's promise returns
          .then ( result, error ) ->
            # handle errors in the promise
            if error
              self.error "#{ self.getTableName() }:model:fetch:error", error
            # done terminates the fiber and returns to the syncronous method
            done error, result

  # wrap Bookshelf to provide syncronous db query methods
  class BookshelfCollection extends Bookshelf.PostgreSQL.Collection
    # wraps the asyncronous fetch method to run in a syncronous fiber
    fetchSync: ( options ) ->
      self = @
      if Meteor.isClient
        self.error "BookshelfModel.fetchSync() can only be called on the server."
      if Meteor.isServer
        # Async is provided by arunoda's awesome `npm` package
        # runSync blocks this fiber until execution is complete
        Async.runSync ( done ) ->
          # call the original Bookshelf.fetch method
          self.fetch( options )
          # terminate the fiber when Bookshelf.fetch's promise returns
          .then ( result, error ) ->
            # handle errors in the promise
            if error
              self.error "#{ self.model.getTableName() }:collection:fetch:error", error
            # done terminates the fiber and returns to the syncronous method
            done error, result

class Model
  # Returns an object containing a shallow copy of the model attributes
  # along with the toJSON value of any relations
  # unless `{shallow: true}` is passed in the options.
  toJSON: ( options ) ->
    self = @
    # create an object of just model attributes
    attrs = _.extend( {}, self.attributes )
    console.log 'start ============================================='
    console.log attrs
    # return if `{ shallow : true }` was passed as an option
    return attrs  if options and options.shallow
    relations = self.relations
    # foreach of this models relations
    for key of relations
      relation = relations[ key ]
      console.log relation
      # if the relation has a toJSON method ( it is a model ) call it
      if relation.toJSON
        attrs[ key ] = relation.toJSON()
        # otherwise just include the relation
      else
        attrs[ key ] = relation
    # if this model has a pivot table
    if self.pivot
      pivot = self.pivot.attributes

      for key of pivot
        attrs[ "_pivot_" + key ] = pivot[ key ]
    console.log 'end ============================================='
    attrs

  # static access to the tableName instance property
  @getTableName: ->
    self = @
    return new self().tableName

  # static access to the relatedTables instance property
  @getRelatedTables: ->
    self = @
    return new self().relatedTables

  # static access to the fields instance property
  @getSchema: ->
    self = @
    return new self().schema


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

# Create a base Model Mixen alias
Mixen.Model = ( modules... ) ->
  if Meteor.isServer
    return Mixen modules..., Model, BookshelfModel, Mixen.Logs()
  if Meteor.isClient
    return Mixen modules..., Model, Mixen.Logs()

# Create a base Collection Mixen alias
Mixen.Collection = ( modules... ) ->
  if Meteor.isServer
    return Mixen modules..., AllowRules, Notifications, Persist, Count, All, Collection, Mixen.Logs(), BookshelfCollection
  if Meteor.isClient
    return Mixen modules..., AllowRules, Notifications, Persist, Count, All, Collection, Mixen.Logs()