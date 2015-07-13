if Npm.require('cluster').isMaster

  Tickets.before.insert (userId, doc) ->
    #Update tag collection for autocomplete.
    doc.tags?.forEach (x) ->
      Tags.upsert {name: x}, {$set: {lastUse: now}}

    #Update queue new counts.
    QueueBadgeCounts.update {queueName: doc.queueName, userId: {$ne: userId}}, { $inc: {count: 1} }, {multi: true}
    
    doc = prepareTicket userId, doc
    notifyTicketAuthor userId, doc


  Tickets.before.update (userId, doc, fieldNames, modifier, options) ->
    _.each fieldNames, (fn) ->
      getEventMessagesFromUpdate userId, doc, fn, modifier

  Changelog.before.insert (userId, doc) ->
    #Server-side note timestamping.
    if doc.type is "note"
      doc.timestamp = new Date()

  Changelog.after.insert (userId, doc) ->
    if doc.type is "note"
      sendNotificationForNote userId, doc
