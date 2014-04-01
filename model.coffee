###
  Bookshelf ORM Initialization
    * [SQL ORM based on Backbone](http://bookshelfjs.org)
    * connect ORM to postgres
###
if Meteor.isClient
  Model = {}
if Meteor.isServer
  Bookshelf = Npm.require 'bookshelf'
  Bookshelf.initialize = _.once Bookshelf.initialize
  Bookshelf = Bookshelf.initialize
    client: 'pg',
    connection:
      host: 'localhost'
      user: 'austin'
  Model = Bookshelf.Model