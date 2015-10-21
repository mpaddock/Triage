@TriageEmailFunctions = {}
@TriageEmailFunctions.getTicketId = (references) ->
  ticketId = null
  r = references.split(/[\s,]+/)
  _.each r, (ref) ->
    id = ref.split('@').shift().substr(1).split('.').pop()
    if Tickets.findOne(id)
      ticketId = id
      console.log "Parsed references, got _id: #{id}"

  return ticketId
