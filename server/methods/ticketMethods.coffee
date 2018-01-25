TicketHelpers = require('/imports/server/util/ticketHelpers.coffee').TicketHelpers


Meteor.methods
    'ticket.create': (ticket) ->
        ticket.tags?.forEach (tag) ->
            Tags.upsert { name: tag }, { $set: { lastUse: new Date() } }

            QueueBadgeCounts.update { queueId: ticket.queueId, userId: { $ne: @userId } },
                { $inc: { count: 1 } },
                { multi: true }

        ticket = TicketHelpers.prepareTicket(ticket, @userId)
        Tickets.insert ticket

    'ticket.closeSilently': (ticketId) ->
        ticket = Tickets.findOne(ticketId)
        if Queues.findOne { name: ticket.queueName, memberIds: @userId }
            d = new Date()

            Tickets.direct.update ticketId, { $set: {
                status: 'Closed'
                timeToClose: (d - ticket.submittedTimestamp) / 1000 # Amount of time to ticket close, in seconds.
                closedTimestamp: d
                closedByUserId: @userId
                closedByUsername: Meteor.users.findOne(@userId).username
            } }

            Changelog.direct.insert
                ticketId: ticketId
                timestamp: new Date()
                authorId: @userId
                authorName: Meteor.users.findOne(@userId)?.username
                type: 'field'
                field: 'status'
                oldValue: ticket.status
                newValue: 'Closed'

    'ticket.associateUser': (ticketId, associatedUserId) ->
        if Tickets.findOne(ticketId).isQueueMemberForTicket(@userId)
            Tickets.update ticketId, { $addToSet: { associatedUserIds: associatedUserId } }
