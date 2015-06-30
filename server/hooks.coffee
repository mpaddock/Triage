if Npm.require('cluster').isMaster

  Changelog.before.insert (userId, doc) ->
    #Server-side note timestamping.
    if doc.type is "note"
      doc.timestamp = new Date()

  Tickets.before.insert (userId, doc) ->
    #True submitter record
    if userId then doc.submittedByUserId = userId
    #Ticket numbering
    max = Tickets.findOne({}, {sort:{ticketNumber:-1}})?.ticketNumber || 0
    doc.ticketNumber = max + 1
    #Server-side timestamping
    now = new Date()
    doc.submittedTimestamp = now
    #Update tag collection for autocomplete
    doc.tags?.forEach (x) ->
      Tags.upsert {name: x}, {$set: {lastUse: now}}
    #Update queue new counts.
    QueueBadgeCounts.update {queueName: doc.queueName}, { $inc: {count: 1} }, {multi: true}

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
              #Adding tags - modify the tags collection.
              _.each tags, (x) ->
                Tags.upsert {name: x}, {$set: {lastUse: new Date()}}
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
          type = "attachment"
          if modifier.$addToSet?.attachmentIds
            file = FileRegistry.findOne modifier.$addToSet.attachmentIds
            otherId = file._id
            message = "attached file #{file.filename}"
          else if modifier.$pull?.attachmentIds
            file = FileRegistry.findOne modifier.$pull.attachmentIds
            otherId = file._id
            message = "removed attached file #{file.filename}"

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

