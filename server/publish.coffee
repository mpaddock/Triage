Meteor.publishComposite 'tickets', (filter, limit, myqueue) ->
  check filter, Object
  #If there's a queue filter, make sure the user has access. If no filter, make the queue filter all the user has access to.
  if filter.queueName? and not Queues.findOne({name: filter.queueName, memberIds: @userId})
    filter.queueName = null
  else if not filter.queueName?
    queues = _.pluck Queues.find({memberIds: @userId}).fetch(), 'name'
    filter.queueName = queues
  if myqueue
    filter.userId = @userId
  else
    filter.userId = null
  mongoFilter = Filter.toMongoSelector filter
  facetPath = Filter.toFacetString filter
  
  {
    find: () ->
      Counts.publish(this, 'ticketCount', Tickets.find(mongoFilter))
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


Meteor.publish 'userData', () ->
  Meteor.users.find {_id: @userId}
Meteor.publish 'allUserData', () ->
  Meteor.users.find {}, {fields: {'_id': 1, 'username': 1, 'mail': 1, 'displayName': 1, 'department': 1, 'physicalDeliveryOfficeName': 1, 'status.online': 1}}

Meteor.publish 'queueNames', () ->
  #Consider only publishing memberIds for queues that the uesr is a member of. Probably not a huge deal.
  Queues.find {}, {fields: {'name': 1, 'memberIds': 1}}

Meteor.publish 'tags', () ->
  Tags.find {}, {fields: {'name': 1}, sort: {lastUse: -1}, limit: 100}
