rootUrl = Meteor.absoluteUrl()

class @NotificationJob extends Job
  handleJob: ->
    Email.send
      from: Meteor.settings.email.fromEmail
      to: @params.email
      subject: @params.subject
      html: @params.html

Tickets.after.insert (userId, doc) ->
  #After insert so we can get ticketNumber.
  user = Meteor.users.findOne(userId)
  if user.notificationSettings.submitted
    subject = "Triage ticket ##{doc.ticketNumber} submitted: #{doc.title}"
    message = "You submitted ticket #{doc.ticketNumber} with body:<br>#{doc.body}<br><br>
      <a href='#{rootUrl}/ticket/#{doc.ticketNumber}'>View the ticket here.</a>"
    
    Job.push new NotificationJob email: user.mail, subject: subject, html: message

Tickets.before.update (userId, doc, fieldNames, modifier) ->
  user = Meteor.users.findOne(userId)
  author = Meteor.users.findOne(doc.authorId)

  if _.contains fieldNames, "status"
    subject = "User #{user.username} changed status for Triage ticket ##{doc.ticketNumber}: #{doc.title}"
    message = "<strong>User #{user.username} changed status for ticket ##{doc.ticketNumber} from
      #{doc.status} to #{modifier.$set.status}.</strong><br>
      The original ticket body was:<br>
      #{doc.body}<br><br>
      <a href='#{rootUrl}/ticket/#{doc.ticketNumber}'>View the ticket here.</a>"
    
    authorSent = false
    if author.notificationSettings.authorStatusChanged
      Job.push new NotificationJob email: author.mail, subject: subject, html: message
      authorSent = true
    _.each doc.associatedUserIds, (a) ->
      unless (a is doc.authorId) and authorSent = true
        aUser = Meteor.users.findOne(a)
        if aUser.notificationSettings.associatedStatusChanged
          Job.push new NotificationJob email: aUser.mail, subject: subject, html: message

  if _.contains fieldNames, "attachmentIds"
    file = FileRegistry.findOne(modifier.$addToSet.attachmentIds)
    subject = "User #{user.username} added an attachment to Triage ticket ##{doc.ticketNumber}: #{doc.title}"
    message = "Attachment #{file.filename} added to ticket #{doc.ticketNumber}.
      <a href='#{rootUrl}/file/#{file.filenameOnDisk}'>View the attachment here.<br><br>
      The original ticket body was:<br>#{doc.body}<br><br>
      <a href='#{rootUrl}/ticket/#{doc.ticketNumber}'>View the ticket here.</a>"
    
    authorSent = false
    if author.notificationSettings.authorAttachment
      Job.push new NotificationJob email: author.mail, subject: subject, html: message
      authorSent = true
    _.each doc.associatedUserIds, (a) ->
      unless (a is doc.authorId) and (authorSent = true)
        aUser = Meteor.users.findOne(a)
        if aUser.notificationSettings.associatedAttachment
          Job.push new NotificationJob email: aUser.mail, subject: subject, html: message

Changelog.before.insert (userId, doc) ->
  if doc.type is "note"
    ticket = Tickets.findOne(doc.ticketId)
    author = Meteor.users.findOne(ticket.authorId)
    user = Meteor.users.findOne(userId)
    authorSent = false
    subject = "Note added to Triage ticket ##{ticket.ticketNumber}: #{ticket.title}"
    message = "<strong>User #{doc.authorName} added a note to ticket ##{ticket.ticketNumber}:</strong><br>
      #{doc.message}<br><br>
      <strong>#{ticket.authorName}'s original ticket body was:</strong><br>
      #{ticket.body}<br><br>
      <a href='#{rootUrl}/ticket/#{ticket.ticketNumber}'>View the ticket here.</a>"

    if (user._id is author._id) and (user.notificationSettings.authorSelfNote)
      Job.push new NotificationJob email: user.mail, subject: subject, html: message
      authorSent = true
    else if author.notificationSettings.authorOtherNote
      Job.push new NotificationJob email: author.mail, subject: subject, html: message
      authorSent = true
    
    _.each ticket.associatedUserIds, (a) ->
      unless (a is author._id) and (authorSent = true)
        aUser = Meteor.users.findOne(a)
        if (aUser._id is userId) and (aUser.notificationSettings.associatedSelfNote)
          Job.push new NotificationJob email: aUser.mail, subject: subject, html: message
        else if aUser.notificationSettings.associatedOtherNote
          Job.push new NotificationJob email: aUser.mail, subject: subject, html: message

