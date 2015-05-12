Template.ticket.helpers
  admin: ->
    _.contains Queues.findOne({name: @queueName})?.memberIds, Meteor.userId()
  author: ->
    Meteor.users.findOne {_id: @authorId}
  ticket: ->
    ticket = Tickets.findOne {ticketNumber: Session.get('ticketNumber')}
    Session.set 'queueName', ticket?.queueName
    return ticket
  changelog: ->
    Changelog.find {ticketId: this._id}, {sort: timestamp: 1}
  changeIsType: (type) ->
    @type is type
  note: ->
    if this.type is "note" then return true else return false
  file: ->
    FileRegistry.findOne {_id: this.valueOf()}
  settings: ->
    {
      position: "top"
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

Template.ticket.events
  'keyup input[name=newNoteAdmin]': (e, tpl) ->
    if (e.which is 13) and (e.target.value isnt "")
      queueName = Tickets.findOne({ticketNumber: Session.get('ticketNumber')}).queueName
      if _.contains Queues.findOne({name: queueName}).memberIds, Meteor.userId()
        body = e.target.value
        hashtags = getTags body
        users = getUserIds body

        if users?.length > 0
          Tickets.update $(e.target).data('ticket'), {$addToSet: {associatedUserIds: $each: users}}

        if hashtags?.length > 0
          Tickets.update $(e.target).data('ticket'), {$addToSet: {tags: $each: hashtags}}

        Changelog.insert
          ticketId: $(e.target).data('ticket')
          timestamp: new Date()
          authorId: Meteor.userId()
          authorName: Meteor.user().username
          type: "note"
          message: $(e.target).val()

        Meteor.call 'setFlag', Meteor.userId(), $(e.target).data('ticket'), 'replied', true

        $(e.target).val("")

  'keyup input[name=newNote]': (e, tpl) ->
    if (e.which is 13) and (e.target.value isnt "")
      Changelog.insert
        ticketId: $(e.target).data('ticket')
        timestamp: new Date()
        authorId: Meteor.userId()
        authorName: Meteor.user().username
        type: "note"
        message: $(e.target).val()
        
      $(e.target).val("")
