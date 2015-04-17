Template.associatedUserPortrait.helpers
  user: -> Meteor.users.findOne {_id: @userId}

Template.associatedUserPortrait.events
  'click a[data-action=removeUser]': (e, tpl) ->
    ticketId = $(e.target).closest('.accordion-body').data('ticket')
    Tickets.update {_id: ticketId}, {$pull: {associatedUserIds: @userId}}
