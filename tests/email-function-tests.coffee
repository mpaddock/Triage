id = "8H3Bj7EY8GNAFYKin"
refs = '<1445454389838.8H3Bj7EY8GNAFYKin@meteordev.as.uky.edu> <04E5ED91-09AF-4491-967A-0CC5C1DCBE8C@uky.edu>'
refs2 = '<1445454389838.8H3Bj7EY8GNAFYKin@meteordev.as.uky.edu>,<04E5ED91-09AF-4491-967A-0CC5C1DCBE8C@uky.edu>'
refs3 = '<04E5ED91-09AF-4491-967A-0CC5C1DCBE8C@uky.edu> <1445454389838.8H3Bj7EY8GNAFYKin@meteordev.as.uky.edu>'
refs4 = '<04E5ED91-09AF-4491-967A-0CC5C1DCBE8C@uky.edu>, <1445454389838.8H3Bj7EY8GNAFYKin@meteordev.as.uky.edu>'

Tinytest.add 'Email Ingestion', (test) ->
  if Meteor.isServer
    unless Tickets.findOne(id)
      Tickets.insert
        _id: id
        title: "An example ticket"
        authorId: 1
        authorName: "mdpadd2"
        body: "This is an example ticket."
        queueName: "App Dev"
        status: "Open"
        submittedByUserId: 1
        submittedTimestamp: new Date(1445456273222)
        ticketNumber: 333
  

    test.equal TriageEmailFunctions.getTicketId(refs), id
    test.equal TriageEmailFunctions.getTicketId(refs2), id
    test.equal TriageEmailFunctions.getTicketId(refs3), id
    test.equal TriageEmailFunctions.getTicketId(refs4), id

    

