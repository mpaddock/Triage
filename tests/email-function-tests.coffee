ticketId = "8H3Bj7EY8GNAFYKin"

Tinytest.add 'Email Ingestion', (test) ->
  if Meteor.isServer
    @Tickets = {}
    @Tickets.findOne = (id) ->
      if id is ticketId
        {
          _id: ticketId
          title: "An example ticket"
          authorId: 1
          authorName: "mdpadd2"
          body: "This is an example ticket."
          queueName: "App Dev"
          status: "Open"
          submittedByUserId: 1
          submittedTimestamp: new Date(1445456273222)
          ticketNumber: 333
        }
      else
        null
  

    test.equal TriageEmailFunctions.getTicketId('<1445454389838.8H3Bj7EY8GNAFYKin@meteordev.as.uky.edu> <04E5ED91-09AF-4491-967A-0CC5C1DCBE8C@uky.edu>'), ticketId
    test.equal TriageEmailFunctions.getTicketId('<1445454389838.8H3Bj7EY8GNAFYKin@meteordev.as.uky.edu>,<04E5ED91-09AF-4491-967A-0CC5C1DCBE8C@uky.edu>'), ticketId
    test.equal TriageEmailFunctions.getTicketId('<04E5ED91-09AF-4491-967A-0CC5C1DCBE8C@uky.edu> <1445454389838.8H3Bj7EY8GNAFYKin@meteordev.as.uky.edu>'), ticketId
    test.equal TriageEmailFunctions.getTicketId('<04E5ED91-09AF-4491-967A-0CC5C1DCBE8C@uky.edu>, <1445454389838.8H3Bj7EY8GNAFYKin@meteordev.as.uky.edu>'), ticketId

    

