@sendNotificationForNote = (userId, doc) ->
  ticket = Tickets.findOne(doc.ticketId)
  ticketAuthor = Meteor.users.findOne(ticket.authorId)
  noteAuthor = Meteor.users.findOne(userId) || Meteor.users.findOne(doc.authorId)
  noteAuthorName = doc.authorName || doc.authorEmail || noteAuthor.username

  title = validator.escape(ticket.title)
  body = validator.escape(ticket.body)
  note = validator.escape(doc.message)

  recipients = []

  subject = "Note added to Triage ticket ##{ticket.ticketNumber}: #{title}"
  emailBody = "<strong>#{noteAuthorName} added a note to ticket ##{ticket.ticketNumber}:</strong><br>
    #{note}<br><br>
    <strong>#{ticket.authorName}'s original ticket body was:</strong><br>
    #{body}"

  if (noteAuthor?._id is ticketAuthor?._id) and (ticketAuthor?.notificationSettings?.authorSelfNote)
    recipients.push(ticketAuthor.mail)
  else if ticketAuthor?.notificationSettings?.authorOtherNote
    recipients.push(ticketAuthor.mail)

  _.each ticket.associatedUserIds, (id) ->
    u = Meteor.users.findOne(id)
    if (u._id is noteAuthor?._id) and (u.notificationSettings?.associatedSelfNote)
      recipients.push(u.mail)
    else if u.notificationSettings?.associatedOtherNote
      recipients.push(u.mail)

  Job.push new NotificationJob
    bcc: _.uniq(recipients)
    ticketId: ticket._id
    subject: subject
    html: emailBody
