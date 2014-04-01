# defined on server and client
class @User extends Model
  # MongoDB
  @collectionName: 'users'
  @meteorCollection: new Meteor.Collection User.collectionName

  # PostgreSQL
  tableName: User.collectionName
  # used for picking the appropriate fields for model.save()
  # TODO : replace with simpleSchema definition
  @fields: ['id', 'username']

  # Related PostgreSQL Tables
  #   * used for fetching materialized model
  @related: ['tweets', 'followers', 'following']
  tweets: ->
    if Meteor.isServer
      @hasMany Tweet, 'user_id'
  followers: ->
    if Meteor.isServer
      @belongsToMany User, 'followers', 'followee', 'follower'
  following: ->
    if Meteor.isServer
      @belongsToMany User, 'followers', 'follower', 'followee'

  @persist:
    # Create a PostgreSQL record from a MongoDB document
    create: (userId, doc)->
      if Meteor.isServer
        # Calling save() persists the model to PostgreSQL
        # Notice that this only saves the model, not its related models
        Mediator.log "#{User.collectionName}:save:#{doc._id}"
        new User().save _.pick(doc, User.fields)
        # Once the model is saved then insert to mongo
        .then( User.persist.related
        , (err)->
          Mediator.log "#{User.collectionName}:save:#{doc._id}:error"
          Mediator.log err
        )
        return false
    # Insert a PostgreSQL model into MongoDB
    insert: Meteor.bindEnvironment( (model) ->
      # insert the model into MongoDB
      _id = User.meteorCollection.insert model.toJSON()
      Mediator.log "#{model.tableName}:insert:#{_id}"
      Mediator.log User.meteorCollection.findOne _id: _id
    )
    update: (userId, docs, fields, modifier) ->
      if Meteor.isServer
        Mediator.log "#{User.collectionName}:update"
        Mediator.log
          userId: userId
          docs: docs
          fields: fields
          modifier: modifier
        return false
    remove: (userId, docs) ->
      if Meteor.isServer
        Mediator.log "#{User.collectionName}:remove"
        Mediator.log
          userId: userId
          docs: docs
        return false
    # Push a PostgreSQL collection into mongoDB
    table: Meteor.bindEnvironment( (table)->
      if Meteor.isServer
        # table is a bookshelf collection
        models = table.toJSON()
        # upsert will create a new model if none exists or merge the model with the new model object
        models.forEach (model) ->
          User.meteorCollection.upsert { id: model.id }, { $set: model }
    )
    related: Meteor.bindEnvironment( (model) ->
      if Meteor.isServer
        Mediator.log "#{model.tableName}:persist:related:#{model.id}"
        # retrieve an instance of this model with all of its related fields from postgres
        model.fetch
          withRelated: User.related
        # Once the related fields have been fetched
        # bindEnvironment is necssary again as this is another promise
        .then( User.persist.insert
        , (err)->
          Mediator.log "#{User.collectionName}:persist:related:#{model.id}:error"
          Mediator.log err
        )
    )
  @setAllowRules: ->
    if Meteor.isServer
      # Allow rules control the clients ability to write to MongoDB
      # This is where the write to PostgreSQL occurs
      # If the PostgreSQL write fails
      #   * then the allow rule fails
      #   * and the write is invalidated on the client
      # Other allow rules may include role validation, write access, and much more
      User.meteorCollection.allow
        # when a client inserts into the user collection
        #   * userId is the user on the client
        #     * userId is really useful for checking authorization on data changes
        #   * doc is the MongoDB document being inserted
        #     * this document has already been created on the client
        #     * if this allow rule fails the client version will be invalidated and removed
        insert: User.persist.create
        update: User.persist.update
        remove: User.persist.remove

  @publish:
    all: ->
      if Meteor.isServer
        Meteor.publish "all_#{User.collectionName}", -> User.meteorCollection.find()
    count: ->
      if Meteor.isServer
        Meteor.publish "#{User.collectionName}_count", ->
          count = 0 # the count of all users
          initializing = true # true only when we first start
          handle = User.meteorCollection.find().observeChanges
            added: =>
              count++ # Increment the count when users are added.
              @changed "#{User.collectionName}-count", 1, {count} unless initializing
            removed: =>
              count-- # Decrement the count when users are removed.
              @changed "#{User.collectionName}-count", 1, {count}
          initializing = false
          # Call added now that we are done initializing. Use the id of 1 since
          # there is only ever one object in the collection.
          @added "#{User.collectionName}-count", 1, {count}
          # Let the client know that the subscription is ready.
          @ready()
          # Stop the handle when the user disconnects or stops the subscription.
          # This is really important or you will get a memory leak.
          @onStop -> handle.stop()

  @handle:
    notification: ->
      if Meteor.isServer
        # if the subscription returns a notification
        if notification = Mediator.subscribe User.collectionName
          channel = notification[0]
          notification = notification[1]
          Mediator.log "#{User.collectionName}:notification:channel:#{notification.channel}"
          switch channel
            when User.collectionName then User.handle.self(notification)
            else Mediator.log "#{User.collectionName}:notification:channel:#{notification.channel}:uncaught"
    self: (notification) ->
      if Meteor.isServer
        Mediator.log "#{User.collectionName}:notification:channel:#{notification.channel}:operation:#{notification.operation}"
        switch notification.operation
          when 'INSERT' then Mediator.log notification
          when 'UPDATE' then Mediator.log notification
          when 'DELETE' then Mediator.log notification
          else Mediator.log "#{User.collectionName}:notification:channel:#{notification.channel}:operation:#{notification.operation}:uncaught"


  # All websocket subscriptions related to this model
  # These subscriptions are defined on the client and server
  @subscribe:
    notifications: ->
      # On the client listen to notifications from the PostgreSQL server
      if Meteor.isServer
        Mediator.listen User.collectionName
        Deps.autorun User.handle.notification
    all: ->
      # On the client listen to changes in the all_users publication
      if Meteor.isClient
        Meteor.subscribe "all_#{User.collectionName}"
    count: ->
      # On the client create a collection and subscribe the the user_count publication
      if Meteor.isClient
        # set the default message for when the subcription is uninitialized
        Session.setDefault "#{User.collectionName}_count", 'Waiting on Subsription'
        # setup User.count collection
        if User.count is undefined
          User.count = new Meteor.Collection "#{User.collectionName}-count"
        # subscribe to users_count reactive publication
        Meteor.subscribe "#{User.collectionName}_count"
        Deps.autorun (->
          users = User.count.findOne()
          unless users is undefined
            Session.set "#{User.collectionName}_count", users.count
        )

  # Fetch the entire users table and its related fields and insert into MongoDB
  @syncronizeMongoDB: ->
    if Meteor.isServer
      User.collection().fetch(
        # build a complete user collection with all related fields
        withRelated: User.related
      ).then( User.persist.table
        , (err)->
          Mediator.log "#{User.collectionName}:sync:error"
          Mediator.log err
      )

  # setup subscriptions / publications
  @initialize: _.once(->
    if Meteor.isServer
      User.setAllowRules()
      User.syncronizeMongoDB()
      User.publish.all()
      User.publish.count()
    User.subscribe.notifications()
  )

###### Views
if Meteor.isClient
  Template.users.count = ->
    return Session.get "#{User.collectionName}_count"

  Template.users.users = ->
    return User.meteorCollection.find()