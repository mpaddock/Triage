@Tickets = new Mongo.Collection 'tickets'
@Tickets.attachSchema new SimpleSchema
  title:
    label: "Title"
    type: String

  body:
    label: "Body"
    type: String

  queueId:
    # Queue to which the ticket belongs
    type: String

  open:
    # Boolean open/resolved flag.
    label: "Ticket Open Status"
    type: Boolean
    defaultValue: true

  status:
    # Defaults to Open, but allow for a Custom Status. Or a pre-defined list of Statuses?
    type: String
    min: 1
    defaultValue: 'Open'

  formFields:
    label: "Form Fields"
    type: Object
    blackbox: true
    optional: true

  authorId:
    # References a userId in Meteor.users
    type: String

  authorName:
    type: String

  tags:
    defaultValue: []
    optional: true
    type: [String]
    min: 1

  associatedUserIds:
    optional: true
    defaultValue: []
    type: [String]

  attachmentIds:
    optional: true
    type: [String]

  submissionData:
    type: Object
    optional: true

  'submissionData.method':
    optional: true
    type: String
    allowedValues: ['Web', 'Email', 'Form', 'Mobile']

  'submissionData.ipAddress':
    optional: true
    type: String

  'submissionData.hostname':
    optional: true
    type: String

  'submissionData.timestamp':
    type: new Date()
    defaultValue: Date.now()

  'submissionData.userId':
    type: String
    optional: true

  lastUpdated:
    type: new Date()
    defaultValue: Date.now

  closedTimestamp:
    optional: true
    type: new Date()

  closedByUserId:
    optional: true
    type: String
    label: "Closed By - ID"

  closedByUsername:
    optional: true
    type: String
    label: "Closed By - Username"


  ticketNumber:
    type: Number
    unique: true
    optional: true

  emailMessageIDs:
    type: [String]
    optional: true

  additionalText:
    type: [String]
    optional: true

@Tickets.helpers
    hasAccessToTicket: (userId) ->
        _.contains(@associatedUserIds, userId) or
        (@authorId is userId) or
        Meteor.users.findOne(userId).isQueueMemberById(@queueId)

    isQueueMemberForTicket: (userId) ->
        Meteor.users.findOne(userId).isQueueMemberById(@queueId)

    author: () ->
        Meteor.users.findOne(@authorId)
