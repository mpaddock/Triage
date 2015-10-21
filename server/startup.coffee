Meteor.startup ->
  Tickets._ensureIndex
    title: "text"
    body: "text"
    additionalText: "text"
    authorName: "text"
    ticketNumber: "text"
    formFields: "text"

  Meteor.settings.queues.forEach (x) ->
    Queues.upsert { name: x.name }, { $set: { securityGroups: x.securityGroups } }

if Meteor.settings?.email?.smtpPipe?
  EmailIngestion.monitorNamedPipe Meteor.settings.email.smtpPipe, (message) ->
    console.log 'incoming email via SMTP', message

    references = message.headers['references'].split(',')
    _.each references, (r) ->
      id = r.split('@').shift().substr(1).split('.').pop()
      if Tickets.findOne(id)
        console.log "incoming email looks to be for ticket with _id #{id}"
        ticketId = id

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
        bcc: message.fromEmail
        subject: "There was a problem ingesting your response."
        html: "Sorry - we had a problem finding the correct ticket to attach your reply to. Please visit the link provided
        in the original email and post your response manually."

