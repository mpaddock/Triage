rootUrl = Meteor.absoluteUrl()
if rootUrl[rootUrl.length-1] == '/'
  rootUrl = rootUrl.substr(0, rootUrl.length-1)
fromEmail = Meteor.settings.email?.fromEmail || "triagebot@as.uky.edu"

class @NotificationJob extends Job
  handleJob: ->
    Email.send
      from: @params.fromEmail
      to: @params.email
      subject: @params.subject
      html: @params.html

Tickets.after.insert (userId, doc) ->
  #After insert so we can get ticketNumber.
  author = Meteor.users.findOne(doc.authorId)
  if author.notificationSettings?.submitted
    title = validator.escape(doc.title)
    body = validator.escape(doc.body)
    subject = "Triage ticket ##{doc.ticketNumber} submitted: #{title}"
    message = "You submitted ticket #{doc.ticketNumber} with body:<br>#{body}<br><br>
      <a href='#{rootUrl}/ticket/#{doc.ticketNumber}'>View the ticket here.</a>"
    
    Job.push new NotificationJob fromEmail: fromEmail, toEmail: author.mail, subject: subject, html: message

Tickets.after.update (userId, doc, fieldNames, modifier) ->
  user = Meteor.users.findOne(userId)
  author = Meteor.users.findOne(doc.authorId)
  title = validator.escape(doc.title)
  body = validator.escape(doc.body)

  if _.contains fieldNames, "status"
    oldStatus = validator.escape(doc.status)
    newStatus = validator.escape(modifier.$set.status)
    subject = "User #{user.username} changed status for Triage ticket ##{doc.ticketNumber}: #{title}"
    message = "<strong>User #{user.username} changed status for ticket ##{doc.ticketNumber} from
      #{oldStatus} to #{newStatus}.</strong><br>
      The original ticket body was:<br>
      #{body}<br><br>
      <a href='#{rootUrl}/ticket/#{doc.ticketNumber}'>View the ticket here.</a>"
    
    authorSent = false
    if author.notificationSettings?.authorStatusChanged
      Job.push new NotificationJob fromEmail: fromEmail, toEmail: author.mail, subject: subject, html: message
      authorSent = true
    _.each doc.associatedUserIds, (a) ->
      unless (a is doc.authorId) and authorSent = true
        aUser = Meteor.users.findOne(a)
        if aUser.notificationSettings?.associatedStatusChanged
          Job.push new NotificationJob fromEmail: fromEmail, toEmail: aUser.mail, subject: subject, html: message

  if _.contains fieldNames, "attachmentIds"
    if modifier.$addToSet?.attachmentIds
      file = FileRegistry.findOne(modifier.$addToSet.attachmentIds)
      subject = "User #{user.username} added an attachment to Triage ticket ##{doc.ticketNumber}: #{title}"
      message = "Attachment #{file.filename} added to ticket #{doc.ticketNumber}.
        <a href='#{rootUrl}/file/#{file.filenameOnDisk}'>View the attachment here.<br><br>
        The original ticket body was:<br>#{body}<br><br>
        <a href='#{rootUrl}/ticket/#{doc.ticketNumber}'>View the ticket here.</a>"
    
      authorSent = false
      if author.notificationSettings?.authorAttachment
        Job.push new NotificationJob fromEmail: fromEmail, toEmail: author.mail, subject: subject, html: message
        authorSent = true
      _.each doc.associatedUserIds, (a) ->
        unless (a is doc.authorId) and (authorSent = true)
          aUser = Meteor.users.findOne(a)
          if aUser.notificationSettings?.associatedAttachment
            Job.push new NotificationJob fromEmail: fromEmail, toEmail: aUser.mail, subject: subject, html: message

Changelog.after.insert (userId, doc) ->
  if doc.type is "note"
    ticket = Tickets.findOne(doc.ticketId)
    author = Meteor.users.findOne(ticket.authorId)
    user = Meteor.users.findOne(userId)
    title = validator.escape(ticket.title)
    body = validator.escape(ticket.body)
    note = validator.escape(doc.message)
    authorSent = false

    subject = "Note added to Triage ticket ##{ticket.ticketNumber}: #{title}"
    message = "<strong>User #{doc.authorName} added a note to ticket ##{ticket.ticketNumber}:</strong><br>
      #{note}<br><br>
      <strong>#{ticket.authorName}'s original ticket body was:</strong><br>
      #{body}<br><br>
      <a href='#{rootUrl}/ticket/#{ticket.ticketNumber}'>View the ticket here.</a>"

    if (user._id is author._id) and (user.notificationSettings?.authorSelfNote)
      Job.push new NotificationJob fromEmail: fromEmail, toEmail: user.mail, subject: subject, html: message
      authorSent = true
    else if (user._id isnt author._id) and (author.notificationSettings?.authorOtherNote)
      Job.push new NotificationJob fromEmail: fromEmail, toEmail: author.mail, subject: subject, html: message
      authorSent = true
    
    _.each ticket.associatedUserIds, (a) ->
      unless (a is author._id) and (authorSent = true)
        aUser = Meteor.users.findOne(a)
        if (aUser._id is userId) and (aUser.notificationSettings?.associatedSelfNote)
          Job.push new NotificationJob fromEmail: fromEmail, toEmail: aUser.mail, subject: subject, html: message
        else if aUser.notificationSettings?.associatedOtherNote
          Job.push new NotificationJob fromEmail: fromEmail, toEmail: aUser.mail, subject: subject, html: message


