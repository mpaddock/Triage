Template.queueSettings.helpers
  queue: -> Queues.findOne({ name: Session.get('queueName') })
  members: -> Meteor.users.find { _id: { $in: @memberIds } }
  isAdmin: -> @ in (Queues.findOne({ name: Session.get('queueName') })?.adminIds || [])
