@Tickets.allow
  insert: -> true
  update: (userId, doc, fields, modifier) ->
    unless _.intersection(['_id', 'authorId', 'authorName', 'body', 'queueName', 'submissionData', 'submittedTimestamp', 'ticketNumber', 'title'], fields).length is 0
      return false
    unless Queues.findOne({name: doc.queueName, memberIds: userId}) or (_.contains doc.associatedUserIds, userId) or (_.contains doc.authorId, userId)
      #Either the user has access to the queue, is associated, or is the ticket author.
      return true
  remove: -> false
