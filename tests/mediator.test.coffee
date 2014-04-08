if Meteor.isServer
  # pgContstring format is `postgres://<host>/<user>
  pgConString = "postgres://localhost/meteor"
else pgConString = null

# test schema
# simple user table with auto inc id
# watched_table trigger fires on all table interactions
# notify_trigger sents a notification with a strigified JSON payload
Schema =
  query: ( query ) ->
    if Meteor.isServer
      pg.connect pgConString, ( err, client, queryDone ) ->
        client.query
          text: query
        queryDone()

  dropQuery: """
    DROP TABLE IF EXISTS users;
    DROP FUNCTION IF EXISTS notify_trigger();
  """

  drop: Meteor._wrapAsync ->
    Schema.query Schema.dropQuery


  create: Meteor._wrapAsync ->
    Schema.query Schema.createQuery

  createQuery: """
    -- Function: notify_trigger()
    CREATE OR REPLACE FUNCTION notify_trigger()
      RETURNS trigger AS
    $BODY$
    DECLARE
      operation varchar;
      channel varchar;
      JSON varchar;
    BEGIN
      -- TG_TABLE_NAME is the name of the table who's trigger called this function
      -- TG_OP is the operation that triggered this function: INSERT, UPDATE or DELETE.

      IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
          JSON = (SELECT row_to_json(NEW));
      ELSEIF TG_OP = 'DELETE' OR TG_OP = 'TRUNCATE' THEN
          JSON = (SELECT row_to_json(OLD));
      END IF;

      -- channel is formatted like 'users_INSERT'
      channel = TG_TABLE_NAME || '_' || TG_OP;
      -- notify the channel with a JSON payload
      PERFORM pg_notify( channel, JSON );

      IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        RETURN NEW;
      ELSEIF TG_OP = 'DELETE' OR TG_OP = 'TRUNCATE' THEN
        RETURN OLD;
      END IF;
    END;
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    ALTER FUNCTION notify_trigger()
      OWNER TO meteor;

    -- Table: users
    CREATE TABLE users
    (
      username text
    )
    WITH (
      OIDS=FALSE
    );
    ALTER TABLE users ADD COLUMN id SERIAL;
    ALTER TABLE users OWNER TO meteor;

    -- Trigger: watched_table on users
    CREATE TRIGGER watched_table
      AFTER INSERT OR UPDATE OR DELETE
      ON users
      FOR EACH ROW
      EXECUTE PROCEDURE notify_trigger();
  """

Tinytest.add "Mediator - defined on server & client", ( test ) ->
  test.notEqual Mediator, undefined, "Expected Mediator to be defined on the server & client."

Tinytest.add "Mediator - initialize()", ( test ) ->
  mediator = Mediator.initialize pgConString
  test.equal mediator.constructor.name, "PrivateMediator", "Expected initialize() to return Private mediator instance."
  mediatorDuplicate = Mediator.initialize()
  test.equal mediatorDuplicate, mediator, "Expected multiple calls to initialize to return the same mediator instance."

Tinytest.add "Mediator - terminate()", ( test ) ->
  mediator = Mediator.initialize pgConString
  Mediator.terminate()
  mediatorNew = Mediator.initialize pgConString
  test.notEqual mediator, mediatorNew, "Calling initialize() after a terminate() returns new mediator instance."

Tinytest.add "Mediator - client", ( test ) ->
  mediator = Mediator.initialize pgConString
  if Meteor.isServer
    test.notEqual mediator.client, undefined, "Expect mediator.client to be defined on the server."
    anotherMediator = Mediator.initialize()
    test.equal anotherMediator.client, mediator.client, "Calling initialize() multiple times should return mediators with the same client."
  if Meteor.isClient
    mediator.client = mediator.client or undefined
    test.equal mediator.client, undefined, "Expect mediator.client to be undefiend on the client."

Tinytest.addAsync "Mediator - publish() / subscribe()", ( test, done ) ->
  mediator = Mediator.initialize pgConString
  payload =
    message: 'test payload'
  channel = 'test-channel'
  subscription = null
  autorun = Deps.autorun Meteor.bindEnvironment ( autorun ) ->
    if subscription = mediator.subscribe channel
      test.equal subscription, [ channel, payload ], "Subscribing to a channel should reactively fetch anything published on that channel."
      Mediator.terminate()
      autorun.stop()
      done()
  mediator.publish channel, payload

Tinytest.addAsync "Mediator - listen()", ( test, done ) ->
  if Meteor.isClient
    try
      mediator.listen 'users'
    catch error
      test.equal false, true, "Calling mediator.listen on the client show throw an error."
      done()
  if Meteor.isServer
    mediator = Mediator.initialize pgConString
    notification = null
    mediator.listen 'users'
    Schema.query "INSERT INTO users ( username ) VALUES ( 'austin' );"
    Deps.autorun Meteor.bindEnvironment ( autorun ) ->
      if notification = mediator.subscribe 'users'
        channel = notification[0]
        notificationObject = notification[1]
        if notificationObject.operation is 'INSERT'
          console.log 'yo'
          test.equal channel, 'users', "Listening to a postgreSQL channel should publish notifications on that channel."
          test.equal notificationObject.channel, 'users', "Notification object should include its channel."
          test.equal notificationObject.operation, 'INSERT', "All notifcation objects should include their operation that triggered them."
          test.equal _.has(JSON.parse(notificationObject.payload).id), true, "All notifications should include a stringified JSON payload with an object id property."
          autorun.stop()
          done()