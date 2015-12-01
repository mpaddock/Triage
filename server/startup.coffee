Meteor.startup ->
  Tickets._ensureIndex
    title: "text"
    body: "text"
    additionalText: "text"
    authorName: "text"
    ticketNumber: "text"
    formFields: "text"

  Meteor.settings.queues.forEach (x) ->
    Queues.upsert { name: x.name }, { $set: { securityGroups: x.securityGroups, settings: x.settings } }

  Facets.configure Tickets,
    tags: [String]
    status: String
    associatedUserIds: [String]

