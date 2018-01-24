Template.navbar.onCreated ->
    @subscribe 'queueNames'
    @subscribe 'queueCounts'

Template.navbar.helpers
  siteTitle: -> Meteor.settings.public.siteTitle
  active: -> @name is Session.get('queueName')
  currentQueue: -> Session.get('queueName') or Meteor.user().defaultQueue or Queues.findOne()?.name
  canViewQueueSettings: -> Meteor.user()?.applicationRole in [ Constants.appAdminRole, Constants.queueAdminRole ]
  canViewAppSettings: -> Meteor.user()?.applicationRole is Constants.appAdminRole
  queueClass: (queueName) -> if queueName is Session.get('queueName') then 'active-queue'
  queues: ->
      filter = { active: true }
      if !Meteor.user().applicationRole is Constants.appAdminRole
          filter.memberIds = Meteor.userId()

      return Queues.find(filter).fetch().map (q) ->
          count = QueueBadgeCounts.findOne({ queueId: q._id, userId: Meteor.userId() })?.count
          return _.extend(q, { count: count })

Template.navbar.events
  'click .navbar-burger': (e, tpl) ->
      tpl.$('.navbar-burger').toggleClass('is-active')
      tpl.$('.navbar-menu').toggleClass('is-active')

  'click a#logout': ->
    Meteor.logout()

  'click button#create-ticket': ->
      Blaze.render Template.newTicketModal, $('body').get(0)
