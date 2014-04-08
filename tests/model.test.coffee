###
  Test Fixtures
###
class TestModel extends Mixen.Model()
  tableName: 'users'
  relatedTables: ['tweets', 'followers', 'following']
  schema: ['id', 'username']

###
  Tests
###
if Meteor.isServer
  Tinytest.add "Model - Model defined on server", (test) ->
    test.notEqual Model, undefined, "Expected Model to be defined on the server."

  Tinytest.add "Model - Mixen.Model defined on server", (test) ->
    test.notEqual Mixen.Model, undefined, "Expected Mixen.Model to be defined on the server."

if Meteor.isClient
  Tinytest.add "Model - Model defined on client", (test) ->
    test.notEqual Model, undefined, "Expected Model to be defined on the client."

  Tinytest.add "Model - Mixen.Model defined on server", (test) ->
    test.notEqual Mixen.Model, undefined, "Expected Mixen.Model to be defined on the client."

Tinytest.add "Model - getTableName()", (test) ->
  testModel = new TestModel()
  test.notEqual testModel.getTableName, undefined, "The getTableName method should be defined on all model instances."
  test.equal testModel.getTableName(), 'users', "Expect getTableName() to return the tableName instance property."

Tinytest.add "Model - getRelatedTables()", (test) ->
  testModel = new TestModel()
  test.notEqual testModel.getRelatedTables, undefined, "The getRelatedTables method should be defined on all model instances."
  test.equal testModel.getRelatedTables(), ['tweets', 'followers', 'following'], "Expect getRelatedTables() to return the relatedTables instance property."

Tinytest.add "Model - getSchema()", (test) ->
  testModel = new TestModel()
  test.notEqual testModel.getSchema, undefined, "The getSchema method should be defined on all model instances."
  test.equal testModel.getSchema(), ['id', 'username'], "Expect getSchema() to return the schema instance property."

