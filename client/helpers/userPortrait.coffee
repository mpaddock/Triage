Template.userPortrait.helpers
  user: -> Meteor.users.findOne @userId
  online: ->
    if @fadeIfOffline
      if Meteor.users.findOne(@userId).status?.idle or not Meteor.users.findOne(@userId).status?.online
        return "offline"

Template.userPortrait.events
  'click a[data-action=removeUser]': (e, tpl) ->
    e.stopPropagation()
    ticketId = Template.parentData(2)._id
    Tickets.update {_id: ticketId}, {$pull: {associatedUserIds: this.userId}}
