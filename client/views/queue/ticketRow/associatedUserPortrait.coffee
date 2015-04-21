Template.associatedUserPortrait.helpers
  user: -> Meteor.users.findOne {_id: this.valueOf()}

Template.associatedUserPortrait.events
  'click a[data-action=removeUser]': (e, tpl) ->
    ticketId = Template.parentData(1)._id
    Tickets.update {_id: ticketId}, {$pull: {associatedUserIds: this.valueOf()}}
