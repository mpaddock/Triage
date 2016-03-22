if Meteor.settings?.email?.smtpPipe?
  EmailIngestion.monitorNamedPipe Meteor.settings.email.smtpPipe, (message) ->
    console.log 'incoming email via SMTP', message
    # Don't process auto-submitted messages - header should be either 'auto-submitted' or 'auto-replied'
    if message.headers['auto-submitted']?.match(/(auto-)\w+/g) or message.headers['x-auto-response-suppress'] is 'All'
      console.log 'auto-generated message, ignoring'
    else if queueId = TriageEmailFunctions.getDirectlyEmailedQueueId message
      # A new submission emailed directly to the queue
      queue = Queues.findOne queueId
      user = Meteor.users.findOne { $or: [ { mail: message.fromEmail}, { emails: message.fromEmail } ] }
      # TODO: handle unknown email address users... probably just issue an error reply
      # TODO: handle getting the quote text if it's a forward instead of a direct email
      ticket =
        title: message.subject
        body: message.body
        authorId: user._id
        authorName: user.name
        submissionData:
          method: 'Email'
        submittedTimestamp: Date.now()
        queueName: queue.name
        attachmentIds: message.attachments
    else
      if ticketId = TriageEmailFunctions.getTicketId message
        # Try to find a user. If no user, just attach the note with the author email address.
        user = Meteor.users.findOne { $or: [ { mail: message.fromEmail }, { emails: message.fromEmail } ] }

        Changelog.insert
          ticketId: ticketId
          timestamp: new Date()
          authorId: user?._id
          authorName: user?.username
          authorEmail: message.fromEmail
          type: "note"
          message: EmailIngestion.extractReplyFromBody message.body

        if user
          Meteor.call 'setFlag', user._id, ticketId, 'replied', true

      else
        # Couldn't find a ticket associated with the references; respond to the user and let them know.
        console.log "couldn't find ticket to attach response to, reporting error to user"
        Email.send
          from: Meteor.settings.email?.fromEmail || "triagebot@triage.as.uky.edu"
          to: message.fromEmail
          subject: "There was a problem ingesting your response."
          html: "Sorry - we had a problem finding the correct ticket to attach your reply to. Please visit the link provided
          in the original email and post your response manually."

