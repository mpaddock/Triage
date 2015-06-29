@Tickets = new Mongo.Collection 'tickets'
@Tickets.attachSchema new SimpleSchema
  title:
    label: "Title"
    type: String
  body:
    label: "Body"
    type: String
  formFields:
    label: "Form Fields"
    type: Object
    blackbox: true
    optional: true
  authorId:
    type: String
  authorName:
    type: String
  status:
    type: String
    defaultValue: 'Open'
  tags:
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
  submittedTimestamp:
    type: new Date()
    defaultValue: Date.now
  closedTimestamp:
    optional: true
    type: new Date()
  queueName:
    type: String
  associatedUserIds:
    optional: true
    type: [String]
  attachmentIds:
    optional: true
    type: [String]
  ticketNumber:
    type: Number
    unique: true
    optional: true
  submittedByUserId:
    #A record of the 'true' submitter for on behalf of submissions.
    type: String
    optional: true

@TicketFlags = new Mongo.Collection 'ticketFlags'
# TODO: SimpleSchema doesnt handle v very well, so skip for now
###@TicketFlags.attachSchema new SimpleSchema
  userId:
    type: String
  ticketId:
    type: String
  k:
    type: String
  v:
    type: Object
    blackbox: true
###

@Changelog = new Mongo.Collection 'changelog'
@Changelog.attachSchema new SimpleSchema
  ticketId:
    type: String
    label: "Ticket ID"
  timestamp:
    type: new Date()
    label: "Timestamp"
  authorId:
    type: String
    label: "Author ID"
  authorName:
    type: String
    label: "Author Name"
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
  otherId:
    type: String
    optional: true

@Queues = new Mongo.Collection 'queues'
@Queues.attachSchema new SimpleSchema
  name:
    type: String
    label: "Name"
  memberIds:
    type: [String]
    label: "Queue Members"
    optional: true
  securityGroups:
    type: [String]
    label: "Security Groups"

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

Meteor.users.attachSchema new SimpleSchema
  username:
    type: String
    label: "Username"
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
    type: String
    label: "Email Address"
  memberOf:
    type: [String]
    label: "Member Of"
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

@Tags = new Mongo.Collection 'tags'
@Tags.attachSchema new SimpleSchema
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
