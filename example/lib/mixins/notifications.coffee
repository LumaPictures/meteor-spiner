# parse notifications and route them to the correct method
class @Notifications
  # catch all notification handler, primary router
  handle_notification: ->
    self = @
    if Meteor.isServer
      # if the subscription returns a notification
      if notification = self.mediator.subscribe self.getTableName()
        channel = notification[0]
        notification = notification[1]
        self.log "notification:channel:#{notification.channel}"
        switch channel
          when self.getTableName() then self.handle_self(notification)
          else self.error "notification:channel:#{notification.channel}:uncaught", notification

  handle_self: (notification) ->
    self = @
    if Meteor.isServer
      self.log "notification:channel:#{notification.channel}:operation:#{notification.operation}"
      switch notification.operation
        when 'INSERT' then self.handle_insert notification
        when 'UPDATE' then self.handle_update notification
        when 'DELETE' then self.handle_delete notification
        else self.error "notification:channel:#{notification.channel}:operation:#{notification.operation}:uncaught", notification

  handle_insert: (notification) ->
    self = @
    if Meteor.isServer
      self.persist_related new self.model JSON.parse notification.payload

  # Once the model is saved then insert to mongo
  handle_update: (notification) ->
    self = @
    self.log notification

  handle_delete: (notification) ->
    self = @
    if Meteor.isServer
      instance = new self.model JSON.parse notification.payload
      self.persist_delete instance

  # All websocket subscriptions related to this model
  # These subscriptions are defined on the client and server
  subscribe_notifications: ->
    self = @
    # On the client listen to notifications from the PostgreSQL server
    if Meteor.isServer
      self.mediator.listen self.getTableName()
      Deps.autorun self.handle_notification.bind(self)

  # On the client listen to changes in the all_<model.tableName> publication
  subscribe_all: ->
    self = @
    if Meteor.isClient
      Meteor.subscribe "all_#{self.getTableName()}"

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

  publish_all: ->
    self = @
    if Meteor.isClient
      self.error "Data can only be published from the server."
    if Meteor.isServer
      Meteor.publish "all_#{self.getTableName()}", -> self.meteorCollection.find()

  publish_count: ->
    self = @
    if Meteor.isClient
      self.error "Data can only be published from the server."
    if Meteor.isServer
      Meteor.publish "#{self.getTableName()}_count", ->
        publish = @
        count = 0 # the count of all <model.tableName>
        initializing = true # true only when we first start
        handle = self.meteorCollection.find().observeChanges
          added: =>
            count++ # Increment the count when <model.tableName> are added.
            publish.changed "#{self.getTableName()}-count", 1, {count} unless initializing
          removed: =>
            count-- # Decrement the count when <model.tableName> are removed.
            publish.changed "#{self.getTableName()}-count", 1, {count}
        initializing = false
        # Call added now that we are done initializing. Use the id of 1 since
        # there is only ever one object in the collection.
        publish.added "#{self.getTableName()}-count", 1, {count}
        # Let the client know that the subscription is ready.
        publish.ready()
        # Stop the handle when the <model.tableName> disconnects or stops the subscription.
        # This is really important or you will get a memory leak.
        publish.onStop -> handle.stop()