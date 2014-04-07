@TweetsCollectionName = 'tweets'
@TweetsMeteorCollection = new Meteor.Collection TweetsCollectionName
@TweetFields = ['id', 'user_id', 'content']
@TweetRelated = ['users']

# Tweet Model
class @Tweet extends Model
  # PostgreSQL
  tableName: TweetsCollectionName
  # belongs to a user
  users: ->
    if Meteor.isServer
      return @belongsTo User, 'user_id'