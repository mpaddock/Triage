@TicketFlags = new Mongo.Collection 'ticketFlags'
@TicketFlags.attachSchema new SimpleSchema
  userId:
    type: String

  ticketId:
    type: String

  key:
    type: String

  value:
    type: Object
    blackbox: true
