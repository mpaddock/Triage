Template.userPortrait.helpers
  user: -> Meteor.users.findOne {_id: this.userId}

Template.userPortrait.events
  'click a[data-action=removeUser]': (e, tpl) ->
    e.stopPropagation()
    ticketId = Template.parentData(2)._id
    Tickets.update {_id: ticketId}, {$pull: {associatedUserIds: this.userId}}
