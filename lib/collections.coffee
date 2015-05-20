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

@Tickets.allow
  insert: -> true
  update: -> true
  remove: -> false

@Tickets.deny
  update: (userId, doc, fields, modifier) ->
    if _.intersection(['_id', 'authorId', 'authorName', 'body', 'queueName', 'submissionData', 'submittedTimestamp', 'ticketNumber', 'title'], fields).length isnt 0
      return true
    unless Queues.findOne({name: doc.queueName, memberIds: userId}) or (_.contains doc.associatedUserIds, userId) or (_.contains doc.authorId, userId)
      return true
  remove: -> true

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

@Changelog.allow
  #Users can't update/insert to the changelog.
  insert: -> false
  update: -> false
  remove: -> false

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

@Queues.allow
  insert: -> false
  update: -> false
  remove: -> false
