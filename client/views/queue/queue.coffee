limitDefault = 20
limitIncrement = 20

Template.queue.helpers
  alpha: ->
    Meteor.settings.public.alpha
  moreToLoad: ->
    if Tickets.find().count() < Counts.get('ticketCount') then return true
  ready: ->
    Session.get 'ready'
  loadingMore: ->
    Session.get 'loadingMore'
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
    }, Session.get('limit'), myqueue, onReady: () ->
      Session.set('loadingMore', false)

  $('[data-toggle=popover]').popover()
  this.find('.animated')?._uihooks =
    insertElement: (node, next) ->
      $(node)
        .hide()
        .insertBefore(next)
        .fadeIn(500)
    removeElement: (node) ->
      $(node).fadeOut 700, () ->
        $(this).remove()

Template.queue.events
  'click a[data-action=loadMore]': (e, tpl) ->
    Session.set 'limit', Session.get('limit') + limitIncrement
    Session.set 'loadingMore', true

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
      
      id = Tickets.insert {
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
      }, (err, res) ->
        if res
          tpl.$('input[name=newTicket]').val('')

