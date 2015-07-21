limit = Meteor.settings?.public?.limitDefault || 20
offsetIncrement = Meteor.settings?.public?.offsetIncrement || 20

Template.queue.helpers
  alpha: ->
    true
  ready: ->
    Session.get 'ready'
  firstVisibleTicket: ->
    if Tickets.find().count() is 0 then 0 else Session.get('offset') + 1
  lastVisibleTicket: ->
    if Session.get('ready')
      Math.min Session.get('offset') + Tickets.find().count(), Counts.get('ticketCount')
    else
      Math.min Session.get('offset') + offsetIncrement, Counts.get('ticketCount')
  lastDisabled: ->
    if Session.get('offset') is 0 then "disabled"
  nextDisabled: ->
    if (Session.get('offset') + offsetIncrement + 1) > Counts.get('ticketCount') then "disabled"
  connected: ->
    Meteor.status().connected
  noTickets: ->
    Tickets.find().count() is 0
  clientCount: ->
    Tickets.find().count()
  search: ->
    Iron.query.get('search')? or Iron.query.get('status')? or Iron.query.get('tag')? or Iron.query.get('user')?
  members: ->
    Queues.findOne({name: Session.get('queueName')})?.memberIds
  queueName: ->
    Session.get 'queueName'
  tickets: ->
    Tickets.find {}, {sort: {submittedTimestamp: -1}}
  addingTicket: ->
    Session.get 'addingTicket'
  pseudoqueue: ->
    Session.get('pseudoQueue') in ['globalQueue', 'userQueue']
  queues: ->
    Queues.find()
  selected: ->
    if Session.get('pseudoQueue')
      if this.name is Meteor.user().defaultQueue then "selected"
    else
      if this.name is Session.get('queueName') then "selected"
  settings: ->
    {
      position: "bottom"
      limit: 5
      rules: [
        {
          token: '@'
          collection: Meteor.users
          field: 'username'
          template: Template.userPill
        }
        {
          token: '#'
          collection: Tags
          field: 'name'
          template: Template.tagPill
          noMatchTemplate: Template.noMatchTagPill
        }
      ]
    }

Template.queue.events
  'click button[data-action=nextPage]': (e, tpl) ->
    start = Number(Iron.query.get('start')) || 0
    if (start + offsetIncrement) < Counts.get('ticketCount')
      Session.set 'newTicketSet', []
      Iron.query.set 'start', start + offsetIncrement
  'click button[data-action=lastPage]': (e, tpl) ->
    start = Number(Iron.query.get('start')) || 0
    Iron.query.set 'start', Math.max start - offsetIncrement, 0
    Session.set 'newTicketSet', []

  'click a[data-action=clearSearch]': (e, tpl) ->
    e.stopPropagation()
    Iron.query.set 'search', ''
    Iron.query.set 'tag', ''
    Iron.query.set 'status', ''
    Iron.query.set 'user', ''
    Iron.query.set 'start', ''

  'click button[data-action=openQuickAdd]': (e, tpl) ->
    Session.set 'addingTicket', !Session.get('addingTicket')

  'keyup input[name=newTicket]': (e, tpl) ->
    if e.which is 13
      submitQuickAddTicket tpl

  'keyup input[name=newTicketStatus]': (e, tpl) ->
    if e.which is 13
      sumbitQuickAddTicket tpl

  'click button[name=quickAddTicket]': (e, tpl) ->
    submitQuickAddTicket tpl

submitQuickAddTicket = (tpl) ->
  tpl.$('.has-error').removeClass('has-error')
  body = tpl.$('input[name=newTicket]').val()
  if body is "" then tpl.$('input[name=newTicket]').closest('div').addClass('has-error')
  status = tpl.$('input[name=newTicketStatus]').val()
  if status is "" then tpl.$('input[name=newTicketStatus]').closest('div').addClass('has-error')
  queue = tpl.$('select[name=queue]')?.val() || Session.get('queueName')
  tags = getTags body
  users = getUserIds body
  if tpl.$('.has-error').length is 0
    Tickets.insert
      title: body
      body: body
      tags: tags
      associatedUserIds: users
      queueName: queue
      authorId: Meteor.userId()
      authorName: Meteor.user().username
      status: status
      submittedTimestamp: new Date()
      submissionData:
        method: "Web"

    tpl.$('input[name=newTicket]').val('')



Template.queue.rendered = ->
  renderedTime = new Date()
  this.autorun ->
    # Highlighting of search terms.
    if Iron.query.get('search') and Session.get('ready')
      Meteor.setTimeout ->
        $('td').unhighlight()
        $('td').highlight(Iron.query.get('search')?.split(','))
      , 500

  this.autorun ->
    queueName = Session.get('queueName') || _.pluck Queues.find().fetch(), 'name'
    filter = {
      queueName: queueName
      search: Iron.query.get 'search'
      status: Iron.query.get 'status'
      tag: Iron.query.get 'tag'
      user: Iron.query.get 'user'
      associatedUser: Iron.query.get 'associatedUser'
    }
    if Session.get('pseudoQueue') is 'userQueue'
      filter.userId = Meteor.userId()
    
    mongoFilter = Filter.toMongoSelector filter
    _.extend mongoFilter, {submittedTimestamp: {$gt: renderedTime}}
    Tickets.find(mongoFilter).observe
      added: (ticket) ->
        if Session.get('offset') < 1
          Session.set 'newTicketSet', _.uniq(Session.get('newTicketSet')?.concat(ticket._id) || [ticket._id])

    Meteor.subscribe 'ticketSet', Session.get('newTicketSet')
