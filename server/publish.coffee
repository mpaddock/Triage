Meteor.publishComposite 'tickets', (filter, offset, limit) ->
  if offset < 0 then offset = 0
  if Filter.verifyFilterObject filter, _.pluck(Queues.find({memberIds: @userId}).fetch(), 'name'), @userId
    mongoFilter = Filter.toMongoSelector filter
    [ticketSet, facets] = Tickets.findWithFacets(mongoFilter, {sort: {submittedTimestamp: -1}, limit: limit, skip: offset})
    ticketSet = _.pluck ticketSet.fetch(), '_id'
  else
    ticketSet = []
  {
    find: () ->
      Counts.publish(this, 'ticketCount', Tickets.find(mongoFilter), { noReady: true })

      Tickets.find({_id: {$in: ticketSet}}, {sort: {submittedTimestamp: -1}})
    children: [
      {
        find: (ticket) ->
          Changelog.find {ticketId: ticket._id}
      },
      {
        find: (ticket) ->
          TicketFlags.find {ticketId: ticket._id, userId: @userId}
      },
      {
        find: (ticket) ->
          if ticket.attachmentIds?.length > 0
            FileRegistry.find {_id: {$in: ticket.attachmentIds}}
      },
      {
        find: ->
          facets
      }
    ]
  }

Meteor.publishComposite 'newTickets', (filter, time) ->
  if Filter.verifyFilterObject filter, _.pluck(Queues.find({memberIds: @userId}).fetch(), 'name'), @userId
    mongoFilter = Filter.toMongoSelector filter
    _.extend mongoFilter, {submittedTimestamp: {$gt: time}}
  {
    find: () ->
      Tickets.find mongoFilter, {sort: {submittedTimestamp: -1}}
    children: [
      {
        find: (ticket) ->
          Changelog.find {ticketId: ticket._id}
      },
      {
        find: (ticket) ->
          TicketFlags.find {ticketId: ticket._id, userId: @userId}
      },
      {
        find: (ticket) ->
          if ticket.attachmentIds?.length > 0
            FileRegistry.find {_id: {$in: ticket.attachmentIds}}
      }
    ]
  }

Meteor.publishComposite 'ticketSet', (ticketSet) ->
  {
    find: () ->
      if not ticketSet then return
      queues = _.pluck Queues.find({memberIds: @userId}).fetch(), 'name'
      Tickets.find {_id: {$in: ticketSet}, $or: [{associatedUserIds: @userId}, {authorId: @userId}, {queueName: {$in: queues}}]}, {sort: {submittedTimestamp: -1}}
    children: [
      {
        find: (ticket) ->
          Changelog.find {ticketId: ticket._id}
      },
      {
        find: (ticket) ->
          TicketFlags.find {ticketId: ticket._id, userId: @userId}
      },
      {
        find: (ticket) ->
          if ticket.attachmentIds?.length > 0
            FileRegistry.find {_id: {$in: ticket.attachmentIds}}
      }
    ]
  }



Meteor.publishComposite 'ticket', (ticketNumber) ->
  {
    find: () ->
      username = Meteor.users.findOne(@userId).username
      queues = _.pluck Queues.find({memberIds: @userId}).fetch(), 'name'
      return Tickets.find {ticketNumber: ticketNumber, $or: [{associatedUserIds: @userId}, {authorId: @userId}, {authorName: username}, {queueName: {$in: queues}}]}
    children: [
      {
        find: (ticket) ->
          Changelog.find {ticketId: ticket._id}
      },
      {
        find: (ticket) ->
          TicketFlags.find {ticketId: ticket._id, userId: @userId}
      },
      {
        find: (ticket) ->
          if ticket.attachmentIds?.length > 0
            FileRegistry.find {_id: {$in: ticket.attachmentIds}}
      }
    ]
  }

Meteor.publish 'userData', () ->
  Meteor.users.find {_id: @userId}

Meteor.publish 'allUserData', () ->
  Meteor.users.find {}, {fields: {'_id': 1, 'username': 1, 'mail': 1, 'displayName': 1, 'department': 1, 'physicalDeliveryOfficeName': 1, 'status.online': 1, 'status.idle': 1}}

Meteor.publish 'queueNames', () ->
  #Consider only publishing memberIds for queues that the uesr is a member of. Probably not a huge deal.
  Queues.find {}, {fields: {'name': 1, 'memberIds': 1}}

Meteor.publish 'tags', () ->
  Tags.find {}, {fields: {'name': 1}, sort: {lastUse: -1}, limit: 100}

Meteor.publish 'queueCounts', () ->
  QueueBadgeCounts.find {userId: @userId}
