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
