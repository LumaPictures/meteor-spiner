@UserCollectionName = 'users'
@UserMeteorCollection = new Meteor.Collection UserCollectionName
@UserFields = ['id', 'username']

# defined on server and client
class @User extends Model
  # PostgreSQL
  tableName: UserCollectionName
  relatedTables: ['tweets', 'followers', 'following']
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
  meteorCollection: UserMeteorCollection


###### Views
if Meteor.isClient
  Template.users.count = ->
    return Session.get "#{UserCollectionName}_count"

  Template.users.users = ->
    return UserMeteorCollection.find()