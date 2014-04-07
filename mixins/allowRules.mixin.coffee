class AllowRules
  # by default writes are not allowed from the client directly to MongoDB
  # when a client inserts into a collection
  #   * userId is the user on the client
  #     * userId is really useful for checking authorization on data changes
  #   * doc is the MongoDB document being inserted
  #     * this document has already been created on the client
  #     * if this allow rule fails the client version will be invalidated and removed
  defaultAllowRules: ->
    return {
      insert: (userId, doc) -> return false
      update: (userId, docs, fields, modifier) -> return false
      remove: (userId, docs) -> return false
    }

  # set the allow rules on the this collection
  # usually called during collection initialization
  setAllowRules: ->
    self = @
    if Meteor.isClient
      self.error "Allow rules can only be set on the server."
    if Meteor.isServer
      # Allow rules control the clients ability to write to MongoDB
      # This is where the write to PostgreSQL occurs
      # If the PostgreSQL write fails
      #   * then the allow rule fails
      #   * and the write is invalidated on the client
      # Other allow rules may include role validation, write access, and much more
      self.meteorCollection.allow _.defaults self.allow(), self.defaultAllowRules()