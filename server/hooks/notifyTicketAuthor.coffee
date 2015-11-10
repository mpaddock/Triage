@notifyTicketAuthor = (userId, doc) ->
  author = Meteor.users.findOne(doc.authorId)
  if author?.notificationSettings?.submitted
    title = escape(doc.title)
    body = escape(doc.body)
    subject = "Triage ticket ##{doc.ticketNumber} submitted: #{title}"
    message = "You submitted ticket ##{doc.ticketNumber} with body:<br>#{body}"
    queue = Queues.findOne({name: doc.queueName})
    if (doc.submissionData?.method is "Form" and queue.settings?.notifyOnAPISubmit) or !(doc.submissionData?.method is "Form")
      Job.push new NotificationJob
        ticketId: doc._id
        bcc: author.mail
        subject: subject
        html: message
