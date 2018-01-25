@Changelog = new Mongo.Collection 'changelog'
@Changelog.attachSchema new SimpleSchema

  ticketId:
    # References a ticket by ID from the Tickets collection
    type: String
    label: "Ticket ID"

  timestamp:
    type: new Date()
    label: "Timestamp"

  authorId:
    # Author of the change event
    type: String
    label: "Author ID"
    optional: true

  authorName:
    type: String
    label: "Author Name"
    optional: true

  authorEmail:
    # Optional - used for email responses to tickets when an appropriate userId can't be found.
    type: String
    label: "Author Email address"
    optional: true

  type:
    type: String
    allowedValues: ['note', 'field', 'attachment']
    label: "Type"

  field:
    type: String
    label: "Field"
    optional: true

  message:
    type: String
    label: "Message"
    optional: true

  oldValue:
    type: String
    label: "Old Value"
    optional: true

  newValue:
    type: String
    label: "New Value"
    optional: true

  otherId:
    type: String
    optional: true

  internal:
    type: Boolean
    optional: true
    defaultValue: false
    label: "Internally Visible Only"

@Changelog.helpers
    author: () ->
        Meteor.users.findOne(@authorId)
