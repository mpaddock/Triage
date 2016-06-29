if Npm.require('cluster').isMaster

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


  # After modification, set unread ticket flag
  Changelog.after.insert (userId, doc) ->
    ticket = Tickets.findOne(doc.ticketId)
    if ticket?.authorId != userId
      TicketFlags.upsert {userId: ticket.authorId, ticketId: doc.ticketId, k: 'unread'},
        $set:
          v: true
    _.each ticket?.associatedUserIds, (u) ->
      if u != userId
        TicketFlags.upsert {userId: u, ticketId: doc.ticketId, k: 'unread'},
          $set:
            v: true

sendNotificationForNote = (userId, doc) ->
  ticket = Tickets.findOne(doc.ticketId)
  ticketAuthor = Meteor.users.findOne(ticket.authorId)
  noteAuthor = Meteor.users.findOne(userId) || Meteor.users.findOne(doc.authorId)
  noteAuthorName = doc.authorName || doc.authorEmail || noteAuthor.username

  title = escapeString(ticket.title)
  body = Parsers.prepareContentForEmail(ticket.body)
  note = Parsers.prepareContentForEmail(doc.message)

  recipients = []

  subject = "Note added to Triage ticket ##{ticket.ticketNumber}: #{title}"
  emailBody = "<strong>#{noteAuthorName} added a note to ticket ##{ticket.ticketNumber}:</strong><br>
    #{note}<br><br>
    <strong>#{ticket.authorName}'s original ticket body was:</strong><br>
    #{body}"

  if (noteAuthor?._id is ticketAuthor?._id) and (ticketAuthor?.notificationSettings?.authorSelfNote) and not doc.internal
    recipients.push(ticketAuthor.mail)
  else if (noteAuthor?._id isnt ticketAuthor?._id) and ticketAuthor?.notificationSettings?.authorOtherNote and not doc.internal
    recipients.push(ticketAuthor.mail)

  _.each ticket.associatedUserIds, (id) ->
    u = Meteor.users.findOne(id)
    if (u._id is noteAuthor?._id) and (u.notificationSettings?.associatedSelfNote)
      recipients.push(u.mail)
    else if (u._id isnt noteAuthor?._id) and u.notificationSettings?.associatedOtherNote
      recipients.push(u.mail)

  if recipients.length > 0
    Job.push new NotificationJob
      bcc: _.uniq(recipients)
      ticketId: ticket._id
      subject: subject
      html: emailBody

