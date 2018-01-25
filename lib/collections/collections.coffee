@UserStats = new Mongo.Collection 'userStats'
@TicketStats = new Mongo.Collection 'ticketStats'

@Tags = new Mongo.Collection 'tags'
@Tags.attachSchema new SimpleSchema
  # Collection to store tags for quick lookup, instead of grabbing them out of the ticket collection.
  # Also useful for mizzao:autocomplete.

  name:
    type: String
    unique: true

  lastUse:
    type: new Date()


@QueueBadgeCounts = new Mongo.Collection 'queueBadgeCounts'
@QueueBadgeCounts.attachSchema new SimpleSchema

  userId:
    type: String
    label: "User ID"

  queueName:
    type: String
    label: "Queue Name"

  count:
    type: Number
