if Npm.require('cluster').isMaster
  Tickets.before.insert (userId, doc) ->
    max = Tickets.findOne({}, {sort:{ticketNumber:-1}})?.ticketNumber || 0
    doc.ticketNumber = max + 1
    doc.submittedTimestamp = new Date()

  Tickets.before.update (userId, doc, fieldNames, modifier, options) ->
    author = Meteor.users.findOne(userId)
    _.each fieldNames, (fn) ->
      switch fn
        when 'tags'
          type = "field"
          if modifier.$addToSet?.tags?
            tags = _.difference modifier.$addToSet.tags.$each, doc.tags
            message = "added tag(s) #{tags}"
          if modifier.$pull?.tags?
            message = "removed tag(s) #{modifier.$pull.tags}"
        when 'status'
          type = "field"
          message = "changed status from #{doc.status} to #{modifier.$set.status}"
        when 'associatedUserIds'
          type = "field"
          if modifier.$addToSet?.associatedUserIds?
            users = _.map modifier.$addToSet.associatedUserIds.$each, (x) ->
              Meteor.users.findOne({_id: x}).username
            message = "associated user(s) #{users}"
          if modifier.$pull?.associatedUserIds?
            user = Meteor.users.findOne({_id: modifier.$pull.associatedUserIds}).username
            message = "disassociated user #{user}"
        when 'attachmentIds'
          file = FileRegistry.findOne modifier.$addToSet.attachmentIds
          type = "attachment"
          otherId = file._id
          message = "attached file #{file.filename}"

      Changelog.insert
        ticketId: doc._id
        timestamp: new Date()
        authorId: author._id
        authorName: author.username
        type: type
        field: fn
        message: message
        otherId: otherId
