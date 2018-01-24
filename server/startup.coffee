Meteor.startup ->
  Tickets._ensureIndex
    title: "text"
    body: "text"
    additionalText: "text"
    authorName: "text"
    ticketNumber: "text"
    formFields: "text"

  Changelog._ensureIndex
    ticketId: 1

  TicketFlags._ensureIndex
    ticketId: 1
    userId: 1

  Facets._ensureIndex
    collection: 1
    facetString: 1

  Facets.configure Tickets,
    tags: [String]
    status: String
    associatedUserIds: [String]

