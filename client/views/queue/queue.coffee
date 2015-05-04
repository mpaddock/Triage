Template.queue.helpers
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
  'click button[data-action=openQuickAdd]': (e, tpl) ->
    Session.set 'addingTicket', !Session.get('addingTicket')

  'click button[data-action=addTicket]': (e, tpl) ->
    body = tpl.find('input[name=newTicket]').value
    queue = tpl.find('select[name=queue]')?.value || Session.get('queueName')
    tags = getTags body
    users = getUsers body
      
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
      if err
        tpl.$('textarea[name=newTicket]').addClass('has-error')
      else
        tpl.$('textarea[name=newTicket]').removeClass('has-error')
        tpl.$('textarea[name=newTicket]').val('')


