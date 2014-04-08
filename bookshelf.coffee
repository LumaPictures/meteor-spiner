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