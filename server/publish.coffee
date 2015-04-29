Meteor.publishComposite 'tickets', (filter, limit) ->
  check filter, Object
  mongoFilter = Filter.toMongoSelector filter
  facetPath = Filter.toFacetString filter
  queueFilter = mongoFilter.queueName?
  {
    find: () ->
      Queues.find {memberIds: @userId}

    children: [
      {
        find: (queue) ->
          Facets.upsert {facet: facetPath},
            {$set: {counts: Facets.compute(filter)}}
          cursor = Facets.find({facet: facetPath})
          cursor.observe
            removed: (oldDoc) ->
              Facets.upsert {facet: oldDoc.facet},
                {$set: {counts: Facets.compute(filter)}}
          return cursor
      },
      {
        find: (queue) ->
          #If there's no defined queue filter, make sure we're still only returning accessibly queued tickets.
          unless queueFilter
            mongoFilter.queueName = queue.name
          Tickets.find mongoFilter, {sort: {submittedTimestamp: -1}, limit: limit}
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
    ]
  }

Meteor.publish 'userData', () ->
  Meteor.users.find {_id: @userId}
Meteor.publish 'allUserData', () ->
  Meteor.users.find {}, {fields: {'_id': 1, 'username': 1, 'mail': 1, 'displayName': 1, 'department': 1}}

Meteor.publish 'queueNames', () ->
  #Consider only publishing memberIds for queues that the uesr is a member of. Probably not a huge deal. 
  Queues.find {}, {fields: {'name': 1, 'memberIds': 1}}

Meteor.publish 'tags', () ->
  Tags.find {}, {fields: {'name': 1}, sort: {lastUse: -1}, limit: 100}
