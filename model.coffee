if Meteor.isServer
  # Initialize PostgreSQL connection and create client pool for Bookshelf
  Bookshelf.PG = Bookshelf.initialize
    client: 'pg',
    connection:
      host: 'localhost'
      user: 'austin'

  class BookshelfModel extends Bookshelf.PG.Model
    # wraps the asyncronous fetch method to run in a syncronous fiber
    fetchSync: (options) ->
      self = @
      Async.runSync ( done ) ->
        self.fetch( options )
        .then (result, error) ->
            if error
              self.error "#{self.getTableName()}:collection:fetch:error", error
            done error, result

  class BookshelfCollection extends Bookshelf.PG.Collection
    # wraps the asyncronous fetch method to run in a syncronous fiber
    fetchSync: (options) ->
      self = @
      Async.runSync ( done ) ->
        self.fetch( options )
        .then (result, error) ->
            if error
              self.error "#{self.model.getTableName()}:collection:fetch:error", error
            done error, result

if Meteor.isClient
  class BookshelfModel
  class BookshelfCollection

# Create a base Model Mixen alias
Mixen.Model = (modules...) ->
  Mixen(modules..., BookshelfModel, Mixen.Logs())

# Create a base Collection Mixen alias
Mixen.Collection = (modules...) ->
  Mixen(modules..., AllowRules, Notifications, Persist, BookshelfCollection, Mixen.Logs())

# mixin that provides methods for get related fields from PostgreSQL, save to PostgreSQL, and some backbone utilities
class Model extends Mixen.Model()
  # static access to the tableName instance property
  @getTableName: ->
    self = @
    return new self().tableName

class Collection extends Mixen.Collection()
  # create collection with all its mixins and setup for app
  initialize: (models, options) ->
    self = @
    self.mediator = Mediator.initialize()
    if Meteor.isServer
      self.setAllowRules()
      self.syncronize_collection()
    self.log "#{self.model.getTableName()}:collection:initialized"

  getTableName: ->
    self = @
    self.model.getTableName()

  allow:
    insert: @persist_create
    update: @persist_update
    remove: @persist_remove