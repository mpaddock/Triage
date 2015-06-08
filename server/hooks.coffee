if Npm.require('cluster').isMaster
  Changelog.before.insert (userId, doc) ->
    #Server-side note timestamping.
    if doc.type is "note"
      doc.timestamp = new Date()

  Tickets.before.insert (userId, doc) ->
    #Ticket numbering and server-side ticket timestamping.
    if userId then doc.submittedByUserId = userId
    max = Tickets.findOne({}, {sort:{ticketNumber:-1}})?.ticketNumber || 0
    doc.ticketNumber = max + 1
    doc.submittedTimestamp = new Date()

  Tickets.before.update (userId, doc, fieldNames, modifier, options) ->
    #Changelog events on ticket updates.
    author = Meteor.users.findOne(userId)
    _.each fieldNames, (fn) ->
      switch fn
        when 'tags'
          type = "field"
          if modifier.$addToSet?.tags?
            tags = _.difference modifier.$addToSet.tags.$each, doc.tags
            unless tags.length is 0
              message = "added tag(s) #{tags}"
          if modifier.$pull?.tags?
            message = "removed tag(s) #{modifier.$pull.tags}"
        when 'status'
          unless doc.status is modifier.$set.status
            type = "field"
            message = "changed status from #{doc.status} to #{modifier.$set.status}"
        when 'associatedUserIds'
          type = "field"
          if modifier.$addToSet?.associatedUserIds?.$each?
            users = _.map _.difference(modifier.$addToSet.associatedUserIds.$each, doc.associatedUserIds), (x) ->
              Meteor.users.findOne({_id: x}).username
            unless users.length is 0
              message = "associated user(s) #{users}"
          else if modifier.$addToSet?.associatedUserIds?
            user = Meteor.users.findOne(modifier.$addToSet.associatedUserIds).username
            message = "associated user #{user}"
          else if modifier.$pull?.associatedUserIds?
            user = Meteor.users.findOne({_id: modifier.$pull.associatedUserIds}).username
            message = "disassociated user #{user}"
        when 'attachmentIds'
          file = FileRegistry.findOne modifier.$addToSet.attachmentIds
          type = "attachment"
          otherId = file._id
          message = "attached file #{file.filename}"

      if message
        Changelog.direct.insert
          ticketId: doc._id
          timestamp: new Date()
          authorId: author._id
          authorName: author.username
          type: type
          field: fn
          message: message
          otherId: otherId
