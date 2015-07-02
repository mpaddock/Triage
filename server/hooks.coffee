rootUrl = Meteor.absoluteUrl()
if rootUrl[rootUrl.length-1] == '/'
  rootUrl = rootUrl.substr(0, rootUrl.length-1)
fromEmail = Meteor.settings.email?.fromEmail || "triagebot@as.uky.edu"
fromDomain = fromEmail.split('@').pop()

makeMessageID = (ticketId) ->
  Date.now()+'.'+ticketId+'@'+fromDomain

class @NotificationJob extends Job
  handleJob: ->
    Email.send
      from: @params.fromEmail
      to: @params.toEmail
      bcc: @params.bcc
      subject: @params.subject
      html: @params.html
      headers:
        'Message-ID': makeMessageID @params.ticketId

if Npm.require('cluster').isMaster

  Changelog.before.insert (userId, doc) ->
    #Server-side note timestamping.
    if doc.type is "note"
      doc.timestamp = new Date()

  Tickets.before.insert (userId, doc) ->
    #Record of 'true' submitter.
    if userId then doc.submittedByUserId = userId

    #Sequential ticket numbering.
    max = Tickets.findOne({}, {sort:{ticketNumber:-1}})?.ticketNumber || 0
    doc.ticketNumber = max + 1

    #Server-side timestamping.
    now = new Date()
    doc.submittedTimestamp = now

    #Update tag collection for autocomplete.
    doc.tags?.forEach (x) ->
      Tags.upsert {name: x}, {$set: {lastUse: now}}

    #Update queue new counts.
    QueueBadgeCounts.update {queueName: doc.queueName}, { $inc: {count: 1} }, {multi: true}

    #Email the author.
    author = Meteor.users.findOne(doc.authorId)
    if author.notificationSettings?.submitted
      title = validator.escape(doc.title)
      body = validator.escape(doc.body)
      subject = "Triage ticket ##{doc.ticketNumber} submitted: #{title}"
      message = "You submitted ticket #{doc.ticketNumber} with body:<br>#{body}<br><br>
        <a href='#{rootUrl}/ticket/#{doc.ticketNumber}'>View the ticket here.</a>"
      if (doc.submissionData?.method is "Form" and Meteor.settings.email.sendEmailOnFormSubmit) or !(doc.submissionData?.method is "Form")
        Job.push new NotificationJob
          ticketId: doc._id
          fromEmail: fromEmail
          bcc: author.mail
          subject: subject
          html: message


  Tickets.before.update (userId, doc, fieldNames, modifier, options) ->
    _.each fieldNames, (fn) ->
      getEventMessagesFromUpdate doc, fn, modifier, user, author

  Changelog.after.insert (userId, doc) ->
    if doc.type is "note"
      ticket = Tickets.findOne(doc.ticketId)
      author = Meteor.users.findOne(ticket.authorId)
      user = Meteor.users.findOne(userId)
      title = validator.escape(ticket.title)
      body = validator.escape(ticket.body)
      note = validator.escape(doc.message)
      recipients = []

      subject = "Note added to Triage ticket ##{ticket.ticketNumber}: #{title}"
      emailBody = "<strong>User #{doc.authorName} added a note to ticket ##{ticket.ticketNumber}:</strong><br>
        #{note}<br><br>
        <strong>#{ticket.authorName}'s original ticket body was:</strong><br>
        #{body}<br><br>
        <a href='#{rootUrl}/ticket/#{ticket.ticketNumber}'>View the ticket here.</a>"

      if (user._id is author._id) and (user.notificationSettings?.authorSelfNote)
        recipients.push(author.mail)
      else if (user._id isnt author._id) and (author.notificationSettings?.authorOtherNote)
        recipients.push(author.mail)

      _.each ticket.associatedUserIds, (a) ->
        aUser = Meteor.users.findOne(a)
        if (aUser._id is userId) and (aUser.notificationSettings?.associatedSelfNote)
          recipients.push(aUser.mail)
        else if aUser.notificationSettings?.associatedOtherNote
          recipients.push(aUser.mail)

      Job.push new NotificationJob
        fromEmail: fromEmail
        bcc: _.uniq(recipients)
        ticketId: ticket._id
        subject: subject
        html: emailBody
