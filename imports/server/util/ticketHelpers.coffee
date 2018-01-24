TicketHelpers = {}

TicketHelpers.prepareTicket = (ticket, userId) ->
  console.log(ticket)
  #Record of 'true' submitter.
  if userId then ticket.submittedByUserId = userId

  #Sequential ticket numbering.
  max = Tickets.findOne({}, {sort:{ticketNumber:-1}})?.ticketNumber || 0
  ticket.ticketNumber = max + 1

  #Server-side timestamping.
  now = new Date()
  ticket.submittedTimestamp = now
  ticket.lastUpdated = now

  return ticket

TicketHelpers.getEventMessagesFromUpdate = (userId, ticket, field, modifier) ->
  user = Meteor.users.findOne(userId)
  author = Meteor.users.findOne(ticket.authorId)
  body = Parsers.prepareContentForEmail(ticket.body)
  switch fn
    when 'queueName'
      type = "field"
      oldValue = ticket.queueName
      newValue = modifier.$set.queueName

    when 'tags'
      type = "field"
      if modifier.$addToSet?.tags?
        tags = _.difference (modifier.$addToSet.tags.$each || [modifier.$addToSet.tags]), ticket.tags
        unless tags.length is 0
          newValue = "#{tags}"
          _.each tags, (x) ->
            Tags.upsert { name: x }, { $set: { lastUse: new Date() } }

      if modifier.$pull?.tags?
        oldValue = "#{modifier.$pull.tags}" #in case its an array.

    when 'status'
      oldStatus = escapeString(ticket.status)
      newStatus = escapeString(modifier.$set.status)
      unless oldStatus is newStatus
        Statuses.upsert { name: newStatus }, { $set: { lastUse: new Date() } }
        type = "field"
        oldValue = oldStatus
        newValue = newStatus
        subject = "User #{user.username} changed status for Triage ticket ##{ticket.ticketNumber}: #{ticket.title}"
        emailBody ="<strong>User #{user.username} changed status for ticket ##{ticket.ticketNumber} from
          #{oldStatus} to #{newStatus}.</strong><br>"
        emailBody+= getTicketInformationForEmail ticket

        recipients = []
        if author.notificationSettings?.authorStatusChanged
          recipients.push(author.mail)

        _.each ticket.associatedUserIds, (a) ->
          aUser = Meteor.users.findOne(a)
          if aUser.notificationSettings?.associatedStatusChanged
            recipients.push(aUser.mail)


    when 'associatedUserIds'
      type = "field"
      recipients = []
      subject = "You have been associated with Triage ticket ##{ticket.ticketNumber}: #{ticket.title}"
      emailBody = "You are now associated with ticket ##{ticket.ticketNumber}.<br>"
      emailBody += getTicketInformationForEmail ticket
      if modifier.$addToSet?.associatedUserIds?
        users = modifier.$addToSet.associatedUserIds.$each || [ modifier.$addToSet.associatedUserIds ]
        associatedUsers = _.map _.difference(users, ticket.associatedUserIds), (x) ->
          u = Meteor.users.findOne({_id: x})
          if u.notificationSettings?.associatedWithTicket
            recipients.push u.mail
          return u.username
        unless associatedUsers.length is 0
          newValue = "#{associatedUsers}"

      else if modifier.$pull?.associatedUserIds?
        associatedUser = Meteor.users.findOne({_id: modifier.$pull.associatedUserIds}).username
        oldValue = "#{associatedUser}"

    when 'attachmentIds'
      type = "attachment"
      if modifier.$addToSet?.attachmentIds
        file = FileRegistry.findOne modifier.$addToSet.attachmentIds
        otherId = file._id
        newValue = file.filename
        subject = "User #{user.username} added an attachment to Triage ticket ##{ticket.ticketNumber}: #{ticket.title}"
        emailBody = "Attachment #{file.filename} added to ticket #{ticket.ticketNumber}.<br>"
        emailBody += getTicketInformationForEmail ticket

        recipients = []
        if author.notificationSettings?.authorAttachment
          recipients.push(author.mail)

        _.each ticket.associatedUserIds, (a) ->
          aUser = Meteor.users.findOne(a)
          if aUser.notificationSettings?.associatedAttachment
            recipients.push(aUser.mail)

      else if modifier.$pull?.attachmentIds
        file = FileRegistry.findOne modifier.$pull.attachmentIds
        otherId = file._id
        oldValue = file.filename
        changelog = "removed attached file #{file.filename}"

  if (oldValue or newValue)
    Changelog.direct.insert
      ticketId: ticket._id
      timestamp: new Date()
      authorId: user._id
      authorName: user.username
      type: type
      field: fn
      oldValue: oldValue
      newValue: newValue
      otherId: otherId

  if emailBody and (recipients.length > 0)
    Job.push new NotificationJob
      bcc: _.uniq(recipients)
      ticketId: ticket._id
      subject: subject
      html: emailBody

exports.TicketHelpers = TicketHelpers
