Template.queue.helpers
  queueAdmin: -> true #Defined queue administrators can set members of the queue (and other things, possibly)
  members: -> ["mdpadd2", "nmad222", "sgcond2", "smbrad3", "shorn2"] #Replaced with actual queue membership.
  queueName: -> Session.get "queueName"
  tickets: -> Tickets.find {queueName: Session.get("queueName")}, {sort: {submittedTimestamp: -1}}
