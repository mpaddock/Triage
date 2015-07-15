@sendNotificationForNote = (userId, doc) ->
  ticket = Tickets.findOne(doc.ticketId)
  author = Meteor.users.findOne(ticket.authorId)
  authorName = doc.authorName || doc.authorEmail
  user = Meteor.users.findOne(userId)
  title = validator.escape(ticket.title)
  body = validator.escape(ticket.body)
  note = validator.escape(doc.message)
  recipients = []

  subject = "Note added to Triage ticket ##{ticket.ticketNumber}: #{title}"
  emailBody = "<strong>#{authorName} added a note to ticket ##{ticket.ticketNumber}:</strong><br>
    #{note}<br><br>
    <strong>#{ticket.authorName}'s original ticket body was:</strong><br>
    #{body}"

  if (user?._id is author?._id) and (user?.notificationSettings?.authorSelfNote)
    recipients.push(author.mail)
  else if (user?._id isnt author?._id) and (author?.notificationSettings?.authorOtherNote)
    recipients.push(author.mail)

  _.each ticket.associatedUserIds, (a) ->
    aUser = Meteor.users.findOne(a)
    if (aUser._id is userId) and (aUser.notificationSettings?.associatedSelfNote)
      recipients.push(aUser.mail)
    else if aUser.notificationSettings?.associatedOtherNote
      recipients.push(aUser.mail)

  Job.push new NotificationJob
    bcc: _.uniq(recipients)
    ticketId: ticket._id
    subject: subject
    html: emailBody
