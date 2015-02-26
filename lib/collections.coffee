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
