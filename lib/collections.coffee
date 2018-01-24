@UserStats = new Mongo.Collection 'userStats'
@TicketStats = new Mongo.Collection 'ticketStats'

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

@TicketFlags = new Mongo.Collection 'ticketFlags'
@TicketFlags.attachSchema new SimpleSchema
  userId:
    type: String

  ticketId:
    type: String

  key:
    type: String

  value:
    type: Object
    blackbox: true

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

@Queues = new Mongo.Collection 'queues'
@Queues.attachSchema new SimpleSchema
  name:
    type: String
    label: "Name"
    unique: true

  memberIds:
    type: [String]
    label: "Queue Members"
    optional: true

  adminIds:
    type: [String]
    label: "Queue Administrators"
    optional: true

  securityGroups:
    type: [String]
    label: "Security Groups"

  stats:
    type: Object
    optional: true

  'stats.week.numSubmitted':
    type: Number
    optional: true

  'stats.week.avgTimeToClose':
    type: Number
    optional: true
    decimal: true

  'stats.month.numSubmitted':
    type: Number
    optional: true

  'stats.month.avgTimeToClose':
    type: Number
    optional: true
    decimal: true

  'stats.weeklyLeader.username':
    type: String
    optional: true

  'stats.weeklyLeader.numClosed':
    type: Number
    optional: true

  'stats.weeklyLeader.avgTimeToClose':
    type: Number
    optional: true
    decimal: true

  settings:
    type: Object
    optional: true

  'settings.notifyOnAPISubmit':
    type: Boolean
    optional: true

  statuses:
    # A list of available Statuses for the queue
    type: [ Object ]
    optional: true

  'statuses.$.name':
    type: String
  'statuses.$.rank':
    type: Number

  active:
    type: Boolean
    defaultValue: true

notificationSettingDefaults =
  submitted: true
  authorSelfNote: true
  authorOtherNote: true
  authorStatusChanged: true
  authorAttachment: true
  associatedSelfNote: true
  associatedOtherNote: true
  associatedStatusChanged: true
  associatedAttachment: true
  associatedWithTicket: true

Meteor.users.attachSchema new SimpleSchema
  username:
    type: String
    label: "Username"
    optional: true

  defaultQueue:
    type: String
    optional: true
    label: "Default Queue"

  displayName:
    type: String
    optional: true
    label: "Display Name"

  employeeNumber:
    type: String
    optional: true
    label: "Employee Number"

  mail:
    optional: true
    type: String
    label: "Email Address"

  memberOf:
    type: [String]
    label: "Member Of"
    defaultValue: []

  notificationSettings:
    type: Object
    defaultValue: notificationSettingDefaults

  department:
    type: String
    optional: true

  'notificationSettings.submitted':
    type: Boolean
  'notificationSettings.authorSelfNote':
    type: Boolean
  'notificationSettings.authorOtherNote':
    type: Boolean
  'notificationSettings.authorStatusChanged':
    type: Boolean
  'notificationSettings.authorAttachment':
    type: Boolean
  'notificationSettings.associatedSelfNote':
    type: Boolean
  'notificationSettings.associatedOtherNote':
    type: Boolean
  'notificationSettings.associatedStatusChanged':
    type: Boolean
  'notificationSettings.associatedAttachment':
    type: Boolean
  'notificationSettings.associatedWithTicket':
    type: Boolean

  physicalDeliveryOfficeName:
    type: String
    label: "Physical Delivery Office"
    optional: true

  services:
    type: Object
    optional: true
    blackbox: true

  status:
    type: Object
    optional: true
    blackbox: true

  title:
    optional: true
    type: String
    label: "Title"

  applicationRole:
    type: String
    defaultValue: "USER"
    allowedValues: [ "USER", "APPADMIN", "QUEUEADMIN" ]

Meteor.users.helpers
  isAppAdmin: -> @applicationRole is "APPADMIN"
  getQueues: -> Queues.find { memberIds: @_id }
  isQueueMemberById: (queueId) -> _.contains Queues.findOne(queueId)?.memberIds, @_id
  isQueueMemberByName: (queueName) -> _.contains Queues.findOne({ name: queueName })?.memberIds, @_id

@Tags = new Mongo.Collection 'tags'
@Tags.attachSchema new SimpleSchema
  # Collection to store tags for quick lookup, instead of grabbing them out of the ticket collection.
  # Also useful for mizzao:autocomplete.

  name:
    type: String
    unique: true

  lastUse:
    type: new Date()


@QueueBadgeCounts = new Mongo.Collection 'queueBadgeCounts'
@QueueBadgeCounts.attachSchema new SimpleSchema

  userId:
    type: String
    label: "User ID"

  queueName:
    type: String
    label: "Queue Name"

  count:
    type: Number
