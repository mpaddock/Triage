rootUrl = Meteor.absoluteUrl()

Tickets.after.insert (userId, doc) ->
  #After insert so we can get ticketNumber.
  user = Meteor.users.findOne(userId)
  if user.notificationSettings.submitted
    title = "Triage ticket ##{doc.ticketNumber} submitted: #{doc.title}"
    message = "You submitted ticket #{doc.ticketNumber} with body:<br>#{doc.body}<br><br>
      <a href='#{rootUrl}/ticket/#{doc.ticketNumber}'>View the ticket here.</a>"
    
    sendNotification user.email, title, message

Tickets.before.update (userId, doc, fieldNames, modifier) ->
  user = Meteor.users.findOne(userId)
  author = Meteor.users.findOne(doc.authorId)

  if _.contains fieldNames, "status"
    title = "User #{user.username} changed status for Triage ticket ##{doc.ticketNumber}: #{doc.title}"
    message = "<strong>User #{user.username} changed status for ticket ##{doc.ticketNumber} from
      #{doc.status} to #{modifier.$set.status}.</strong><br>
      The original ticket body was:<br>
      #{doc.body}<br><br>
      <a href='#{rootUrl}/ticket/#{doc.ticketNumber}'>View the ticket here.</a>"
    
    authorSent = false
    if author.notificationSettings.authorStatusChanged
      sendNotification author.mail, title, message
      authorSent = true
    _.each doc.associatedUserIds, (a) ->
      unless (a is doc.authorId) and authorSent = true
        aUser = Meteor.users.findOne(a)
        if aUser.notificationSettings.associatedStatusChanged
          sendNotification aUser.mail, title, message

  if _.contains fieldNames, "attachmentIds"
    title = "User #{user.username} added an attachment to Triage ticket ##{doc.ticketNumber}: #{doc.title}"
    message = "An attachment was added to ticket ##{doc.ticketNumber}. The original ticket body was:<br>
      #{doc.body}<br><br>
      <a href='#{rootUrl}/ticket/#{doc.ticketNumber}'>View the ticket here.</a>"
    
    authorSent = false
    if author.notificationSettings.authorAttachment
      sendNotification author.mail, title, message
      authorSent = true
    _.each doc.associatedUserIds, (a) ->
      unless (a is doc.authorId) and (authorSent = true)
        aUser = Meteor.users.findOne(a)
        if aUser.notificationSettings.associatedAttachment
          sendNotification aUser.mail, title, message

Changelog.before.insert (userId, doc) ->
  if doc.type is "note"
    ticket = Tickets.findOne(doc.ticketId)
    author = Meteor.users.findOne(ticket.authorId)
    user = Meteor.users.findOne(userId)
    authorSent = false
    title = "Note added to Triage ticket ##{ticket.ticketNumber}: #{ticket.title}"
    message = "<strong>User #{doc.authorName} added a note to ticket ##{ticket.ticketNumber}:</strong><br>
      #{doc.message}<br><br>
      <strong>#{ticket.authorName}'s original ticket body was:</strong><br>
      #{ticket.body}<br><br>
      <a href='#{rootUrl}/ticket/#{ticket.ticketNumber}'>View the ticket here.</a>"

    if (user._id is author._id) and (user.notificationSettings.authorSelfNote)
      sendNotification(user.mail, title, message)
      authorSent = true
    else if author.notificationSettings.authorOtherNote
      sendNotification(author.mail, title, message)
      authorSent = true
    
    _.each doc.associatedUserIds, (a) ->
      unless (a is author._id) and (authorSent = true)
        aUser = Meteor.users.findOne(a)
        if (aUser._id is userId) and (aUser.notificationSettings.associatedSelfNote)
          sendNotification aUser.email, title, message
        else if aUser.notificationSettings.associatedOtherNote
          sendNotification aUser.mail, title, message

@sendNotification = (email, title, message) ->
  Email.send
    from: Meteor.settings.email.fromEmail
    to: email
    subject: title
    html: message
