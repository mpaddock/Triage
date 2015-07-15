Meteor.startup ->
  Meteor.settings.queues.forEach (x) ->
    Queues.upsert {name: x.name}, {$set: {securityGroups: x.securityGroups}}

if Meteor.settings?.email?.smtpPipe?
  EmailIngestion.monitorNamedPipe Meteor.settings.email.smtpPipe, (message) ->
    console.log 'incoming email via SMTP', message

    ticketId = message.headers['in-reply-to'].split('@').shift().substr(1).split('.').pop()
    user = Meteor.users.findOne {$or: [ { mail: message.fromEmail }, { emails: message.fromEmail } ]}

    # TODO: what if user is not found? automatically create account for email address?

    Changelog.insert
      ticketId: ticketId
      timestamp: new Date()
      authorId: user?._id
      authorName: user?.username
      authorEmail: message.fromEmail
      type: "note"
      message: EmailIngestion.extractReplyFromBody message.body

    Meteor.call 'setFlag', user._id, ticketId, 'replied', true

