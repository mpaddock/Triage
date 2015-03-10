Template.ticketRow.events
  'keyup input[name=newNote]': (e, tmpl) ->
    if e.which is 13
      Changelog.insert
        ticketId: this._id
        timestamp: new Date()
        authorName: Meteor.user().username #Make this name when we publish the profile
        authorId: Meteor.userId()
        type: "note"
        message: e.target.value

      Meteor.call 'setFlag', Meteor.userId(), this._id, 'replied', true


      $(e.target).val("")


Template.ticketRow.rendered = ->
  $('form[name=ticketForm]').submit (e) -> e.preventDefault()

Template.ticketRow.helpers
  notes: -> Changelog.find {ticketId: this._id, type: "note"}
  repliedTo: ->
    TicketFlags.findOne({userId: Meteor.userId(), ticketId: this._id, k: 'replied'})
