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
