if Meteor.settings?.email?.smtpPipe?
  EmailIngestion.monitorNamedPipe Meteor.settings.email.smtpPipe, (message) ->
    console.log 'incoming email via SMTP', message

    if queueId = TriageEmailFunctions.getDirectlyEmailedQueueId message
      # A new submission emailed directly to the queue - we check this BEFORE checking
      # if the message was auto-generated, since forwarded emails give auto-generated header
      queue = Queues.findOne queueId
      user = Meteor.users.findOne { $or: [ { mail: message.fromEmail}, { emails: message.fromEmail } ] }
      unless user
        console.log "couldn't find user corresponding to <#{message.fromEmail}>, reporting error to user"
        Email.send
          from: Meteor.settings.email?.fromEmail || "triagebot@triage.as.uky.edu"
          to: message.fromEmail
          subject: "There was a problem ingesting your ticket."
          html: "Sorry - we were not able to identify a user from this email address.  Please make sure you have
          logged into "+Meteor.absoluteUrl()+" before trying to email tickets directly to this address."
        return

      ticket =
        title: message.subject
        body: EmailIngestion.extractReplyFromBody message.body
        authorId: user._id
        authorName: user.username
        submissionData:
          method: 'Email'
        submittedTimestamp: Date.now()
        queueName: queue.name
        attachmentIds: message.attachments

      if ticket.body != message.body
        ticket.formFields =
          'Full Message': message.body

      Tickets.insert ticket

    else if message.headers['auto-submitted']?.match(/(auto-)\w+/g) or message.headers['x-auto-response-suppress'] is 'All'
      # Don't process auto-submitted messages - header should be either 'auto-submitted' or 'auto-replied'
      console.log 'auto-generated message, ignoring'
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

        _.each message.attachments, (a) ->
          console.log "message has attachment with id #{a}"
          # No way to trick collection-hooks into thinking there's a user doing these actions,
          # so we update the changelog manually.
          file = FileRegistry.findOne(a)
          Tickets.direct.update ticketId, { $addToSet: { attachmentIds: file._id } }

          Changelog.direct.insert
            ticketId: ticketId
            timestamp: new Date()
            authorId: user?._id
            authorName: user?.username
            authorEmail: message.fromEmail
            type: "attachment"
            otherId: file._id
            newValue: file.filename

          Job.push new TextAggregateJob
            ticketId: ticketId
            text: [file.filename]


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

