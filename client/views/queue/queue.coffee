Template.queue.helpers
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
    Session.get('queueName') in ['globalQueue', 'userQueue']
  queues: ->
    Queues.find()
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
  $('[data-toggle=popover]').popover()
  $(window).scroll () ->
    if $(window).scrollTop() + $(window).height() is $(document).height()
      Session.set 'limit', Session.get('limit') + 30

Template.queue.created = () ->
  Session.setDefault 'limit', 30

Template.queue.events
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


