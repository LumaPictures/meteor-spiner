# defined on server and client
class @User extends Model
  # PostgreSQL
  tableName: 'users'
  relatedTables: ['tweets', 'followers', 'following']
  schema: ['id', 'username']
  # used for picking the appropriate fields for model.save()
  tweets: ->
    if Meteor.isServer
      @hasMany Tweet, 'user_id'
  # Notice that user is self referenced, this is due to followers being a user pivot table
  followers: ->
    if Meteor.isServer
      @belongsToMany User, 'followers', 'followee', 'follower'
  following: ->
    if Meteor.isServer
      @belongsToMany User, 'followers', 'follower', 'followee'

class @UserCollection extends Collection
  model: User
  meteorCollection: new Meteor.Collection User.getTableName()
