Meteor.startup ->
  Meteor.settings.queues.forEach (x) ->
    Queues.upsert {name: x.name}, {$set: {securityGroups: x.securityGroups}}

if Meteor.settings?.email?.smtpPipe?
  EmailIngestion.monitorNamedPipe Meteor.settings.email.smtpPipe, (message) ->
    console.log 'incoming email via SMTP', message

    ticketId = message.headers['in-reply-to'].split('@').shift().split('.').pop()
    user = Meteor.users.find({mail: message.fromEmail})

    # TODO: what if user is not found? automatically create account for email address?

    Changelog.insert
      ticketId: ticketId
      timestamp: new Date()
      authorId: user._id
      authorName: user.username
      type: "note"
      message: message.body

    Meteor.call 'setFlag', user._id, ticketId, 'replied', true

