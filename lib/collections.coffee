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
  authorId:
    type: String
  status:
    type: String
    defaultValue: 'open'
  tags:
    optional: true
    type: [String]
  submissionData:
    type: Object
  'submissionData.method':
    type: String
    allowedValues: ['Web', 'Email', 'Form', 'Mobile']
  'submissionData.ipAddress':
    type: String
  'submissionData.hostname':
    type: String
  submittedTimestamp:
    type: new Date()
  closedTimestamp:
    optional: true
    type: new Date()
  queueName:
    type: [String]
  associatedUserIds:
    optional: true
    type: [String]
  attachmentIds:
    optional: true
    type: [String]


@Changelog = new Mongo.Collection 'changelog'
@Changelog.attachSchema new SimpleSchema
  ticketId:
    type: String
    label: "Ticket ID"
  timestamp:
    type: new Date()
    label: "Timestamp"
  authorName:
    type: String
    label: "Author Name"
  authorId:
    type: String
    label: "Author ID"
  type:
    type: String
    allowedValues: ['note', 'field']
    label: "Type"
  field:
    type: String
    label: "Field"
    optional: true
  message:
    type: String
    label: "Message"
    optional: true

@Queues = new Mongo.Collection 'queues'
@Queues.attachSchema new SimpleSchema
  name:
    type: String
    label: "Name"
  admins:
    type: [String]
    label: "Queue Administrators"
  members:
    type: [String]
    label: "Queue Members"
