Template.ticketHeadingPanels.helpers
  queueMember: ->
      Meteor.user().isQueueMemberById(@queueId)
  submittedByOther: ->
    @submittedByUserId and @authorId isnt @submittedByUserId
  author: ->
    Meteor.users.findOne {_id: @authorId}

Template.ticketHeadingPanels.events
  'click a[name="changeQueue"]': (e, tpl) ->
    Blaze.renderWithData Template.sendToAnotherQueueModal, { ticketId: @_id }, $('body').get(0)
    $('#sendToAnotherQueueModal').modal('show')
