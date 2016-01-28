@Tickets.allow
  insert: -> true
  update: (userId, doc, fields, modifier) ->
    unless _.intersection(['_id', 'authorId', 'authorName', 'body', 'submissionData', 'submittedTimestamp', 'ticketNumber', 'title'], fields).length is 0
      return false
    userIds = Filters.getSharedUserIds.concat(userId)
    if Queues.findOne({name: doc.queueName, memberIds: userId})? or _.intersection(doc.associatedUserIds, userIds).length or _.contains(userIds, doc.authorId)
      #Either the user has access to the queue, is associated, or is the ticket author.
      return true
    console.log "Ticket update #{modifier} on #{fields} failed: user lacks correct access to update this ticket."
    return false
  remove: -> false

Meteor.users.allow
  insert: -> false
  update: (userId, doc, fields, modifier) ->
    if doc._id is userId and _.intersection(['_id', 'department', 'displayName', 'employeeNumber', 'givenName', 'memberOf', 'services', 'status', 'title', 'username'], fields).length is 0
      return true
    else
      return false
  remove: -> false

@Changelog.allow
  insert: (userId, doc) ->
    if doc.type is "note"
      return true
