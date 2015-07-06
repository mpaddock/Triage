@prepareTicket = (userId, doc) ->
  #Record of 'true' submitter.
  if userId then doc.submittedByUserId = userId

  #Sequential ticket numbering.
  max = Tickets.findOne({}, {sort:{ticketNumber:-1}})?.ticketNumber || 0
  doc.ticketNumber = max + 1

  #Server-side timestamping.
  now = new Date()
  doc.submittedTimestamp = now
