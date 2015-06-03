Template.ticket.helpers
  admin: ->
    _.contains Queues.findOne({name: @queueName})?.memberIds, Meteor.userId()
  ticket: ->
    ticket = Tickets.findOne {ticketNumber: Session.get('ticketNumber')}
    Session.set 'queueName', ticket?.queueName
    return ticket
  body: ->
    new Spacebars.SafeString _.map(@body.split('\n'), (p) -> "<p>#{p}</p>").join('')
  changelog: ->
    Changelog.find {ticketId: this._id}, {sort: timestamp: 1}
