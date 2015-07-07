@prepareTicket = (userId, doc) ->
  #Record of 'true' submitter.
  d = doc
  if userId then d.submittedByUserId = userId

  #Sequential ticket numbering.
  max = Tickets.findOne({}, {sort:{ticketNumber:-1}})?.ticketNumber || 0
  d.ticketNumber = max + 1

  #Server-side timestamping.
  now = new Date()
  d.submittedTimestamp = now

  return d
