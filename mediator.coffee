###
  ```
    Mediator Notification Client
      * Present on both client and server
      * Mediator.log wraps console.log
      * Listens to postgres notification channels defined by Mediator.listen
      * Listens on all operations by default ( INSERT, UPDATE, DELETE
      * Persistent Connection to PostgreSQL
      * Reactive notification to client and server

    Example PostgreSQL Trigger
      -- Trigger: watched_table on users
      -- DROP TRIGGER watched_table ON users;
      CREATE TRIGGER watched_table
        AFTER INSERT OR UPDATE OR DELETE
        ON users
        FOR EACH ROW
        EXECUTE PROCEDURE notify_trigger();

    Example PostgreSQL Trigger Function
      -- Function: notify_trigger()
      -- DROP FUNCTION notify_trigger();
      CREATE OR REPLACE FUNCTION notify_trigger()
        RETURNS trigger AS
      $BODY$
      DECLARE
        channel varchar;
        JSON varchar;
      BEGIN
        -- TG_TABLE_NAME is the name of the table who's trigger called this function
        -- TG_OP is the operation that triggered this function: INSERT, UPDATE or DELETE.
        -- channel is formatted like 'users_INSERT'
        channel = TG_TABLE_NAME || '_' || TG_OP;
        JSON = (SELECT row_to_json(new));
        PERFORM pg_notify( channel, JSON );
        RETURN new;
      END;
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION notify_trigger()
        OWNER TO postgresql;
  ```
###
class Mediator
  # You can add statements inside the class definition
  # which helps establish private scope (due to closures)
  # instance is defined as null to force correct scope
  instance = null
  # Create a private class that we can initialize however
  # defined inside this scope to force the use of the
  # singleton class.
  class Private extends Mixen.Logs()
    constructor: ( pgConString ) ->
      self = @
      if Meteor.isServer
        unless self.pgConString
          unless pgConString
            self.error 'A connection string is required to initialize a mediator e.g. (postgres://localhost/user)'
          self.pgConString = pgConString
        @connect()
      self.log "mediator:initialized"

    # Mediator notification channels
    channels: {}

    # Connect to the PostgreSQL notification channels
    connect: ->
      self = @
      if Meteor.isClient
        self.error "Mediator can only connect to PostgreSQL from the server."
      if Meteor.isServer
        # wrap the async connect method of pg.client to return syncronously
        asyncConnect = Async.runSync ( done ) ->
          # Define PostgreSQL client
          client = new pg.Client self.pgConString
          # Create persistent connection to PostgreSQL
          client.connect ( error ) ->
            if error
              self.error "mediator:connect:error", error
            else
              done null, client

        self.client = asyncConnect.result
        # postgres notification event handler
        self.client.on "notification", ( notification ) ->
          # write record to mongo or something
          self.log "mediator:notification:#{ notification.channel }"
          notification = self.parse notification
          self.publish notification.channel, notification
        self.client.on 'error', (err) ->
          self.error "mediator:client:error", err

    # Listen to the PostgreSQL notification channels defined by channel
    listen: ( channel ) ->
      self = @
      if Meteor.isClient
        self.error "You can only listen to a PostgreSQL notification channel on the server."
      if Meteor.isServer
        # the strings must be escaped like this due to PostgreSQL being extremely sensitive to text types
        self.client.query 'LISTEN "' + channel + '_INSERT"'
        self.client.query 'LISTEN "' + channel + '_UPDATE"'
        self.client.query 'LISTEN "' + channel + '_DELETE"'

    # parse a postgresql notifcation into a mediator notification
    parse: ( notification ) ->
      self = @
      notification =
        channel: notification.channel.split('_')[0]
        operation: notification.channel.split('_')[1]
        payload: notification.payload
      self.log notification
      return notification

    # Create a reactive publication the the specified channel
    publish: ( name ) ->
      self = @
      self.channels[ name ].args = _.toArray arguments
      self.channels[ name ].deps.changed()

    # Create a reactive subscription for the specified channel
    subscribe: ( name ) ->
      self = @
      unless self.channels[ name ]
        self.channels[ name ] =
          deps: new Deps.Dependency
          args: null
      self.channels[ name ].deps.depend()
      self.channels[ name ].args

  # This is a static method used to either retrieve the
  # instance or create a new one.
  @initialize: ( pgConString =  null ) ->
    instance ?= new Private pgConString
