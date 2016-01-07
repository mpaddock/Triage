if Meteor.settings?.email?.smtpPipe?
  EmailIngestion.monitorNamedPipe Meteor.settings.email.smtpPipe, (message) ->
    console.log 'incoming email via SMTP', message
    ticketId = TriageEmailFunctions.getTicketId message
    # Don't process auto-submitted messages - header should be either 'auto-submitted' or 'auto-replied'
    if message.headers['auto-submitted']?.match(/(auto-)\w+/g)
      console.log 'auto-generated message, ignoring'
    else
      if ticketId
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
        Email.send
          from: Meteor.settings.email?.fromEmail || "triagebot@triage.as.uky.edu"
          to: message.fromEmail
          subject: "There was a problem ingesting your response."
          html: "Sorry - we had a problem finding the correct ticket to attach your reply to. Please visit the link provided
          in the original email and post your response manually."

