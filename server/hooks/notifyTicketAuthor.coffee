@notifyTicketAuthor = (userId, doc) ->
  author = Meteor.users.findOne(doc.authorId)
  if author.notificationSettings?.submitted
    title = validator.escape(doc.title)
    body = validator.escape(doc.body)
    subject = "Triage ticket ##{doc.ticketNumber} submitted: #{title}"
    message = "You submitted ticket ##{doc.ticketNumber} with body:<br>#{body}"
    if (doc.submissionData?.method is "Form" and Meteor.settings.email.sendEmailOnFormSubmit) or !(doc.submissionData?.method is "Form")
      Job.push new NotificationJob
        ticketId: doc._id
        bcc: author.mail
        subject: subject
        html: message
