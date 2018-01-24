Meteor.publishComposite 'tickets', (filter, offset, limit) ->
  filter.queueName = null
  mongoFilter = Filter.toMongoSelector filter

  {
    find: () ->
      Counts.publish(this, 'ticketCount', Tickets.find(mongoFilter), { noReady: true })
      return Tickets.find()

      Tickets.find { _id: { $in: ticketSet } },
        sort:
          submittedTimestamp: -1
        fields:
          emailMessageIDs: 0
          additionalText: 0
  }



Meteor.publishComposite 'ticket', (ticketNumber) ->
  {
    find: () ->
      username = Meteor.users.findOne(@userId).username
      queues = _.pluck Queues.find({memberIds: @userId}).fetch(), 'name'
      return Tickets.find
        ticketNumber: ticketNumber

    children: [
      {
        find: (ticket) ->
          filter = { ticketId: ticket._id }
          if not Queues.findOne({name: ticket.queueName, memberIds: @userId})? then _.extend filter, { internal: { $ne: true } }
          Changelog.find filter
      },
      {
        find: (ticket) ->
          TicketFlags.find { ticketId: ticket._id, userId: @userId }
      },
      {
        find: (ticket) ->
          if ticket.attachmentIds?.length > 0
            FileRegistry.find { _id: { $in: ticket.attachmentIds } }
      }
    ]
  }

Meteor.publish 'userData', ->
  Meteor.users.find { _id: @userId }

Meteor.publish 'allUserData', ->
  if @userId
    Meteor.users.find {}, { fields: { '_id': 1, 'username': 1, 'mail': 1, 'displayName': 1, 'department': 1, 'physicalDeliveryOfficeName': 1, 'status.online': 1, 'status.idle': 1 } }

Meteor.publish 'allQueues', ->
  if Roles.checkPermissions @userId, 'allQueues'
    Queues.find {}

Meteor.publish 'queueNames', ->
  if @userId
    Queues.find { active: true }, { fields: { 'name': 1, 'memberIds': 1, 'stats': 1, 'active': 1 } }

Meteor.publish 'tags', ->
  if @userId
    Tags.find {}, { fields: { 'name': 1 }, sort: { lastUse: -1 }, limit: 100 }

Meteor.publish 'queueCounts', ->
  QueueBadgeCounts.find { userId: @userId }

Meteor.publish 'unattachedFiles', (fileIds) ->
  # Only return the files if they're not associated with a ticket yet for some security.
  unless Tickets.findOne { attachmentIds: {$in: fileIds } }
    return FileRegistry.find { _id: {$in: fileIds } }

Meteor.publish 'file', (fileId) ->
  queues = _.pluck Queues.find({memberIds: @userId}).fetch(), 'name'
  username = Meteor.users.findOne(@userId).username
  if Tickets.findOne { attachmentIds: fileId , $or: [
    { associatedUserIds: @userId },
    { authorId: @userId },
    { authorName: username },
    { queueName: { $in: queues } }
  ] }
    return FileRegistry.find { _id: fileId }
