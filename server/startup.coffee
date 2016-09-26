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

  Meteor.settings.public = _.extend
      reopenAllowedTimespan: 7*24*60*60
    , Meteor.settings.public

  Facets.configure Tickets,
    tags: [String]
    status: String
    associatedUserIds: [String]

