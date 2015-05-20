@Tickets.allow
  insert: -> true
  update: -> true
  remove: -> false

@Tickets.deny
  update: (userId, doc, fields, modifier) ->
    if _.intersection(['_id', 'authorId', 'authorName', 'body', 'queueName', 'submissionData', 'submittedTimestamp', 'ticketNumber', 'title'], fields).length isnt 0
      return true
    unless Queues.findOne({name: doc.queueName, memberIds: userId}) or (_.contains doc.associatedUserIds, userId) or (_.contains doc.authorId, userId)
      #Either the user has access to the queue, is associated, or is the ticket author.
      return true
  remove: -> true

@TicketFlags.allow
  insert: -> true
  update: -> true
  remove: -> true

@Changelog.allow
  #Users can't update/insert to the changelog.
  insert: -> false
  update: -> false
  remove: -> false

@Queues.allow
  insert: -> false
  update: -> false
  remove: -> false
