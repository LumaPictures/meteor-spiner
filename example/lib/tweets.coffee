# Tweet Model
class @Tweet extends Mixen.Model()
  # PostgreSQL
  tableName: 'tweets'
  relatedTables: ['users']
  schema: ['id', 'user_id', 'content']
  # belongs to a user
  users: ->
    if Meteor.isServer
      return @belongsTo User, 'user_id'

class @TweetCollection extends Mixen.Collection()
  model: Tweet
  meteorCollection: new Meteor.Collection Tweet.getTableName()