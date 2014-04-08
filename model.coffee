class Model
  # Returns an object containing a shallow copy of the model attributes
  # along with the toJSON value of any relations
  # unless `{shallow: true}` is passed in the options.
  toJSON: ( options ) ->
    self = @
    # create an object of just model attributes
    attrs = _.extend( {}, self.attributes )
    console.log 'start ============================================='
    console.log attrs
    # return if `{ shallow : true }` was passed as an option
    return attrs  if options and options.shallow
    relations = self.relations
    # foreach of this models relations
    for key of relations
      relation = relations[ key ]
      console.log relation
      # if the relation has a toJSON method ( it is a model ) call it
      if relation.toJSON
        attrs[ key ] = relation.toJSON()
        # otherwise just include the relation
      else
        attrs[ key ] = relation
    # if this model has a pivot table
    if self.pivot
      pivot = self.pivot.attributes

      for key of pivot
        attrs[ "_pivot_" + key ] = pivot[ key ]
    console.log 'end ============================================='
    attrs

  # static access to the tableName instance property
  getTableName: ->
    self = @
    return self.tableName

  # static access to the relatedTables instance property
  getRelatedTables: ->
    self = @
    return self.relatedTables

  # static access to the fields instance property
  getSchema: ->
    self = @
    return self.schema

# Create a base Model Mixen alias
Mixen.Model = ( modules... ) ->
  if Meteor.isServer
    return Mixen modules..., Model, BookshelfModel, Mixen.Logs()
  if Meteor.isClient
    return Mixen modules..., Model, Mixen.Logs()