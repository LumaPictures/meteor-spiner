class Persist
  # Create a PostgreSQL record from a MongoDB document
  persist_create: (userId, doc) ->
    self = @
    if Meteor.isClient
      self.error "A document can only be persisted from the server."
    if Meteor.isServer
      # Calling save() persists the model to PostgreSQL
      # Notice that this only saves the model, not its related models
      model = new self.model()
      saveSync = model.saveSync doc
      unless saveSync.error
        # calling persist related retrieves the related fields for this document
        # it then persists the joined document to mongoDB
        fetchRelatedModel = model.fetchSync withRelated: model.relatedTables
        unless fetchRelatedModel.error
          self.meteorCollection.upsert { id: model.id }, { $set: model.toJSON() }
          self.log "mongodb:#{ self.getTableName() }:upsert:#{ doc._id }"
          # return true signals that the document has been sucessfully persisted
          # TODO: still returns false because otherwise a duplicate doc is created
          return false
      return false

  # Insert a PostgreSQL model into MongoDB
  persist_insert: ( model ) ->
    self = @
    if Meteor.isClient
      self.error "A document can only be persisted from the server."
    if Meteor.isServer
      # insert the model into MongoDB
      _id = self.meteorCollection.upsert model.toJSON()
      self.log "#{ model.tableName }:persist:insert:#{ _id }"

  # Upsert a PostgreSQL model into MongoDB
  persist_upsert: ( model ) ->
    self = @
    if Meteor.isClient
      self.error "A document can only be persisted from the server."
    if Meteor.isServer
      # upsert the model into MongoDB
      self.meteorCollection.upsert { id: model.id }, { $set: model.toJSON() }
      self.log "#{ model.tableName }:persist:upsert:id:#{ model.id }"

  persist_update: ( userId, docs, fields, modifier ) ->
    self = @
    if Meteor.isClient
      self.error "A document can only be persisted from the server."
    if Meteor.isServer
      self.log "#{ self.model.getTableName() }:persist:update"
      self.log
        userId: userId
        docs: docs
        fields: fields
        modifier: modifier
      return false

  persist_remove: ( userId, docs ) ->
    self = @
    if Meteor.isClient
      self.error "A document can only be persisted from the server."
    if Meteor.isServer
      self.log "#{ self.model.getTableName() }:persist:remove"
      self.log
        userId: userId
        docs: docs
      return false

  persist_delete: ( model ) ->
    self = @
    if Meteor.isClient
      self.error "A document can only be persisted from the server."
    if Meteor.isServer
      self.log "#{ self.model.getTableName() }:persist:delete"
      self.meteorCollection.remove id: model.id

  # Push a PostgreSQL collection into mongoDB
  persist_collection: ( collection ) ->
    self = @
    if Meteor.isClient
      self.error "A document can only be persisted from the server."
    if Meteor.isServer
      self.log "#{ self.model.getTableName() }:persist:collection"
      # upsert will create a new model if none exists or merge the model with the new model object
      # TODO : could the toArray() be the reason for the messed up models?
      collection.toArray().forEach (model) -> self.persist_upsert model

  persist_related: ( model ) ->
    self = @
    if Meteor.isClient
      self.error "A document can only be persisted from the server."
    if Meteor.isServer
      # retrieve an instance of this model with all of its related fields from postgres
      fetchRelatedModel = model.fetchSync withRelated: self.model.relatedTables
      unless fetchRelatedModel.error
        self.persist_upsert fetchRelatedModel.result
        self.log "#{ model.tableName }:persist:related:#{ model.id }"

  # Fetch the entire users table and its related fields and insert into MongoDB
  # once ensures that this method can only be called once
  # TODO : remove once in favor of smarter sync method
  syncronize_collection: ->
    self = @
    if Meteor.isClient
      self.error "A collection can only be sync'd from the server."
    if Meteor.isServer
      # build a complete user collection with all related fields
      self.log "#{ self.model.getTableName() }:collection:syncronize:start"
      fetchRelatedCollection = self.fetchSync withRelated: self.model.getRelatedTables()
      unless fetchRelatedCollection.error
        self.persist_collection fetchRelatedCollection.result
        self.log "#{ self.model.getTableName() }:collection:syncronize:end"
