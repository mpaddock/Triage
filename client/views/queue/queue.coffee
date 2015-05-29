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
    Math.min Session.get('offset') + offsetIncrement, Counts.get('ticketCount')
  lastDisabled: ->
    unless Number(Iron.query.get('page')) > 1 then "disabled"
  nextDisabled: ->
    unless ((Iron.query.get('page') || 1) * offsetIncrement) < Counts.get('ticketCount') then "disabled"
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
  psuedoqueue: ->
    Session.get('pseudoQueue') in ['globalQueue', 'userQueue']
  queues: ->
    Queues.find()
  selected: ->
    if this.name is Meteor.user().defaultQueue then "selected"
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

Template.queue.rendered = () ->

  this.autorun () ->
    if Session.get('pseudoQueue') is 'userQueue' then myqueue = true else myqueue = false
    Meteor.subscribe 'tickets', {
      queueName: Session.get('queueName')
      search: Iron.query.get('search')
      status: Iron.query.get('status')
      tag: Iron.query.get('tag')
      user: Iron.query.get('user')
    }, Session.get('offset'), limit, myqueue, onReady: () ->
      Session.set('loadingMore', false)

Template.queue.events
  'click button[data-action=nextPage]': (e, tpl) ->
    if ((Iron.query.get('page') || 1) * offsetIncrement) < Counts.get('ticketCount')
      Iron.query.set 'page', (Number(Iron.query.get('page')) || 1)+ 1
  'click button[data-action=lastPage]': (e, tpl) ->
    if Iron.query.get('page') > 1
      Iron.query.set 'page', Number(Iron.query.get('page')) - 1
  'click a[data-action=clearSearch]': (e, tpl) ->
    e.stopPropagation()
    Iron.query.set 'search', ''
    Iron.query.set 'tag', ''
    Iron.query.set 'status', ''
    Iron.query.set 'user', ''

  'click button[data-action=openQuickAdd]': (e, tpl) ->
    Session.set 'addingTicket', !Session.get('addingTicket')

  'keyup input[name=newTicket]': (e, tpl) ->
    if e.which is 13
      body = tpl.find('input[name=newTicket]').value
      queue = tpl.find('select[name=queue]')?.value || Session.get('queueName')
      tags = getTags body
      users = getUserIds body
      
      id = Tickets.insert
        title: body
        body: body
        tags: tags
        associatedUserIds: users
        queueName: queue
        authorId: Meteor.userId()
        authorName: Meteor.user().username
        status: "Open"
        submittedTimestamp: new Date()
        submissionData:
          method: "Web"
     
      tpl.$('input[name=newTicket]').val('')

