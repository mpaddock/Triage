@TriageEmailFunctions = {}
@TriageEmailFunctions.getTicketId = (message) ->
  ticketId = null
  r = message?.headers['references'].split(/[\s,]+/)
  _.each r, (ref) ->
    id = ref.split('@').shift().substr(1).split('.').pop()
    if Tickets.findOne(id)
      ticketId = id
      console.log "Parsed references, got _id: #{id}"

  if not ticketId
    # If we don't find anything in the references, check in-reply-to just in case.
    id = message?.headers['in-reply-to']?.split('@').shift().substr(1).split('.').pop()
    if Tickets.findOne(id)
      ticketId = id
      console.log "Parsed in-reply-to, got _id: #{id}"

  return ticketId

@TriageEmailFunctions.getDirectlyEmailedQueueId = (message) ->
  for q in Meteor.settings.queues
    if q.email == message.toEmail
      return Queues.findOne({name: q.name})._id
