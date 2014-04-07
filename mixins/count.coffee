# Provides a reactive count subscription and publication
class Count
  publish_count: ->
    self = @
    if Meteor.isClient
      self.error "Data can only be published from the server."
    if Meteor.isServer
      Meteor.publish "#{ self.getTableName() }_count", ->
        publish = @
        count = 0 # the count of all <model.tableName>
        initializing = true # true only when we first start
        handle = self.meteorCollection.find().observeChanges
          added: =>
            count++ # Increment the count when <model.tableName> are added.
            publish.changed "#{ self.getTableName() }-count", 1, { count } unless initializing
          removed: =>
            count-- # Decrement the count when <model.tableName> are removed.
            publish.changed "#{ self.getTableName() }-count", 1, { count }
        initializing = false
        # Call added now that we are done initializing. Use the id of 1 since
        # there is only ever one object in the collection.
        publish.added "#{ self.getTableName() }-count", 1, { count }
        # Let the client know that the subscription is ready.
        publish.ready()
        # Stop the handle when the <model.tableName> disconnects or stops the subscription.
        # This is really important or you will get a memory leak.
        publish.onStop -> handle.stop()

  # On the client create a collection and subscribe the the <model.tableName>_count publication
  subscribe_count: ->
    self = @
    if Meteor.isClient
      # set the default message for when the subcription is uninitialized
      Session.setDefault "#{self.getTableName()}_count", 'Waiting on Subsription'
      # setup <model.tableName>.count collection
      if self.count is undefined
        self.count = new Meteor.Collection "#{self.model.getTableName()}-count"
      # subscribe to <model.tableName>_count reactive publication
      Meteor.subscribe "#{self.getTableName()}_count"
      Deps.autorun (->
        models = self.count.findOne()
        unless models is undefined
          Session.set "#{self.getTableName()}_count", models.count
      )
