# parse notifications and route them to the correct method
class Notifications
  # catch all notification handler, primary router
  handle_notification: ->
    self = @
    if Meteor.isServer
      # if the subscription returns a notification
      if notification = self.mediator.subscribe self.getTableName()
        channel = notification[0]
        notification = notification[1]
        self.log "notification:channel:#{ notification.channel }"
        switch channel
          when self.getTableName() then self.handle_self notification
          else self.error "notification:channel:#{ notification.channel} :uncaught", notification

  handle_self: (notification) ->
    self = @
    if Meteor.isServer
      self.log "notification:channel:#{ notification.channel }:operation:#{ notification.operation }"
      switch notification.operation
        when 'INSERT' then self.handle_insert notification
        when 'UPDATE' then self.handle_update notification
        when 'DELETE' then self.handle_delete notification
        else self.error "notification:channel:#{ notification.channel }:operation:#{ notification.operation }:uncaught", notification

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