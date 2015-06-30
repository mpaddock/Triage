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
    user = Meteor.users.findOne(userId)
    author = Meteor.users.findOne(doc.authorId)
    title = validator.escape(doc.title)
    body = validator.escape(doc.body)

    _.each fieldNames, (fn) ->
      switch fn

        when 'tags'
          type = "field"
          if modifier.$addToSet?.tags?
            tags = _.difference modifier.$addToSet.tags.$each, doc.tags
            unless tags.length is 0
              changelog = "added tag(s) #{tags}"
              _.each tags, (x) ->
                Tags.upsert {name: x}, {$set: {lastUse: new Date()}}

          if modifier.$pull?.tags?
            changelog = "removed tag(s) #{modifier.$pull.tags}"

        when 'status'
          oldStatus = validator.escape(doc.status)
          newStatus = validator.escape(modifier.$set.status)
          unless oldStatus is newStatus
            type = "field"
            changelog = "changed status from #{oldStatus} to #{newStatus}"
            subject = "User #{user.username} changed status for Triage ticket ##{doc.ticketNumber}: #{title}"
            emailBody ="<strong>User #{user.username} changed status for ticket ##{doc.ticketNumber} from
              #{oldStatus} to #{newStatus}.</strong><br>
              The original ticket body was:<br>
              #{body}<br><br>
              <a href='#{rootUrl}/ticket/#{doc.ticketNumber}'>View the ticket here.</a>"

            recipients = []
            if author.notificationSettings?.authorStatusChanged
              recipients.push(author.mail)

            _.each doc.associatedUserIds, (a) ->
                aUser = Meteor.users.findOne(a)
                if aUser.notificationSettings?.associatedStatusChanged
                  recipients.push(aUser.mail)


        when 'associatedUserIds'
          type = "field"
          if modifier.$addToSet?.associatedUserIds?.$each?
            users = _.map _.difference(modifier.$addToSet.associatedUserIds.$each, doc.associatedUserIds), (x) ->
              Meteor.users.findOne({_id: x}).username
            unless users.length is 0
              changelog = "associated user(s) #{users}"
          else if modifier.$addToSet?.associatedUserIds?
            user = Meteor.users.findOne(modifier.$addToSet.associatedUserIds).username
            changelog = "associated user #{user}"
          else if modifier.$pull?.associatedUserIds?
            user = Meteor.users.findOne({_id: modifier.$pull.associatedUserIds}).username
            changelog = "disassociated user #{user}"

        when 'attachmentIds'
          type = "attachment"
          if modifier.$addToSet?.attachmentIds
            file = FileRegistry.findOne modifier.$addToSet.attachmentIds
            otherId = file._id
            changelog = "attached file #{file.filename}"
            subject = "User #{user.username} added an attachment to Triage ticket ##{doc.ticketNumber}: #{title}"
            emailBody = "Attachment #{file.filename} added to ticket #{doc.ticketNumber}.
              <a href='#{rootUrl}/file/#{file.filenameOnDisk}'>View the attachment here.<br><br>
              The original ticket body was:<br>#{body}<br><br>
              <a href='#{rootUrl}/ticket/#{doc.ticketNumber}'>View the ticket here.</a>"

            recipients = []
            if author.notificationSettings?.authorAttachment
              recipients.push(author.mail)

            _.each doc.associatedUserIds, (a) ->
              aUser = Meteor.users.findOne(a)
              if aUser.notificationSettings?.associatedAttachment
                recipients.push(aUser.mail)
 
          else if modifier.$pull?.attachmentIds
            file = FileRegistry.findOne modifier.$pull.attachmentIds
            otherId = file._id
            changelog = "removed attached file #{file.filename}"

      if changelog
        Changelog.direct.insert
          ticketId: doc._id
          timestamp: new Date()
          authorId: author._id
          authorName: author.username
          type: type
          field: fn
          message: changelog
          otherId: otherId
    
      if emailBody
        Job.push new NotificationJob
          fromEmail: fromEmail
          bcc: _.uniq(recipients)
          ticketId: doc._id
          subject: subject
          html: emailBody


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
