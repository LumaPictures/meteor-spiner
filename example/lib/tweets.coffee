# Tweet Model
class @Tweet extends Model
  tableName: 'tweets'
  # belongs to a user
  users: ->
    if Meteor.isServer
      return @belongsTo User, 'user_id'