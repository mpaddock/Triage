Meteor.publishComposite 'tickets', (filter, offset, limit, myqueue) ->
  if @userId
    check filter, Object
    if filter.queueName? and not Queues.findOne({name: filter.queueName, memberIds: @userId})
      #If there's a queue filter, make sure the user has access.
      filter.queueName = null
    else if myqueue
      filter.userId = @userId
      filter.queueName = _.pluck Queues.find({}, {sort: {name: 1}}).fetch(), 'name'
    else if not filter.queueName?
      filter.userId = null
      filter.queueName = _.pluck Queues.find({memberIds: @userId}, {sort: {name: 1}}).fetch(), 'name'
    else
      filter.userId = null

    if not (filter.status or filter.ticketNumber)
      #If no status filter and we're not looking at a specific ticket, default to 'not Closed' tickets.
      filter.status = "!Closed"

    mongoFilter = Filter.toMongoSelector filter
    facetPath = Filter.toFacetString filter

  {
    find: () ->
      Counts.publish(this, 'ticketCount', Tickets.find(mongoFilter), { noReady: true })
      Tickets.find mongoFilter, {sort: {submittedTimestamp: -1}, limit: limit, skip: offset}
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
      {
        find: () ->
          Facets.upsert {facet: facetPath},
            {$set: {counts: Facets.compute(filter)}}
          cursor = Facets.find({facet: facetPath})
          cursor.observe
            removed: (oldDoc) ->
              Facets.upsert {facet: oldDoc.facet},
                {$set: {counts: Facets.compute(filter)}}
          return cursor
      }
    ]
  }

Meteor.publishComposite 'ticket', (ticketNumber) ->
  find: () ->
    #Check username for API submissions that may not have an authorId associated?
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

Meteor.publish 'userData', () ->
  Meteor.users.find {_id: @userId}

Meteor.publish 'allUserData', () ->
  Meteor.users.find {}, {fields: {'_id': 1, 'username': 1, 'mail': 1, 'displayName': 1, 'department': 1, 'physicalDeliveryOfficeName': 1, 'status.online': 1}}

Meteor.publish 'queueNames', () ->
  #Consider only publishing memberIds for queues that the uesr is a member of. Probably not a huge deal.
  Queues.find {}, {fields: {'name': 1, 'memberIds': 1}}

Meteor.publish 'tags', () ->
  Tags.find {}, {fields: {'name': 1}, sort: {lastUse: -1}, limit: 100}
