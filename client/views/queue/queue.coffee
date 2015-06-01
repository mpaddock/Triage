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
    if (Session.get('offset') - offsetIncrement + 1) <= 0 then "disabled"
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

Template.queue.events
  'click button[data-action=nextPage]': (e, tpl) ->
    start = Number(Iron.query.get('start')) || 0
    if (start + offsetIncrement) < Counts.get('ticketCount')
      Iron.query.set 'start', start + offsetIncrement
  'click button[data-action=lastPage]': (e, tpl) ->
    start = Number(Iron.query.get('start')) || 0
    if (start - offsetIncrement) >= 0
      Iron.query.set 'start', start - offsetIncrement

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

