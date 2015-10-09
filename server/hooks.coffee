if Npm.require('cluster').isMaster

  Tickets.before.insert (userId, doc) ->
    # Update tag and status collections for autocomplete.
    now = new Date()
    doc.tags?.forEach (x) ->
      Tags.upsert { name: x }, { $set: { lastUse: now } }

    Statuses.upsert { name: doc.status }, { $set: { lastUse: now } }

    # Update queue new counts.
    QueueBadgeCounts.update { queueName: doc.queueName, userId: { $ne: userId } }, { $inc: { count: 1 } }, { multi: true }


    # Add author's displayName and department to the text index.
    author = Meteor.users.findOne(doc.authorId)
    Job.push new TextAggregateJob
      ticketId: doc._id
      text: [ author?.displayName, author?.department ]

    # Set the ticket number, store the ticket submitter, server-side timestamp, notify author.
    doc = prepareTicket userId, doc
    notifyTicketAuthor userId, doc
    
    if doc.attachmentIds
      text = []
      _.each doc.attachmentIds, (id) ->
        text.push(FileRegistry.findOne(id).filename)
      Job.push new TextAggregateJob
        ticketId: doc._id
        text: text

  Tickets.before.update (userId, doc, fieldNames, modifier, options) ->
    _.each fieldNames, (fn) ->

      if fn is 'attachmentIds' and modifier.$addToSet?.attachmentIds
        id = modifier.$addToSet.attachmentIds
        console.log FileRegistry.findOne(id).filename
        Job.push new TextAggregateJob
          ticketId: doc._id
          text: [FileRegistry.findOne(id).filename]

      if fn is 'status' and modifier.$set.status is 'Closed'
        d = new Date()
        Tickets.direct.update doc._id, { $set: {
          timeToClose: (d - doc.submittedTimestamp) / 1000 # Amount of time to ticket close, in seconds.
          closedTimestamp: d
          closedByUserId:  userId
          closedByUsername: Meteor.users.findOne(userId).username
        } }

      getEventMessagesFromUpdate userId, doc, fn, modifier

  Changelog.before.insert (userId, doc) ->
    #Server-side note timestamping.
    if doc.type is "note"
      doc.timestamp = new Date()

  Changelog.after.insert (userId, doc) ->
    if doc.type is "note"
      authorName = doc.authorName || doc.authorEmail

      Job.push new TextAggregateJob
        ticketId: doc.ticketId
        text: [doc.message, authorName]

      sendNotificationForNote userId, doc
