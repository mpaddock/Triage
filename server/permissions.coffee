@Tickets.allow
  insert: (userId, doc) ->
    # Member of at least one queue.
    Queues.findOne({memberIds: userId})?
  update: (userId, doc, fields, modifier) ->
    unless _.intersection(['_id', 'authorId', 'authorName', 'body', 'submissionData', 'submittedTimestamp', 'ticketNumber', 'title'], fields).length is 0
      return false
    if Queues.findOne({name: doc.queueName, memberIds: userId})? or (_.contains doc.associatedUserIds, userId) or (doc.authorId == userId)
      #Only allow changing status of closed ticket within a certain time frame after close.
      if doc.status == 'Closed' and 'status' in fields
        closedFor = (Date.now() - doc.closedTimestamp)/1000
        allowed = Meteor.settings?.public?.reopenAllowedTimespan || 604800
        if closedFor > allowed
          console.log "Denying status change of closed ticket #{doc._id}, which has been closed for #{closedFor}s"
          return false
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
