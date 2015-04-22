Template.requesterPortrait.helpers
  user: ->
    return Meteor.users.findOne({_id: this.userId})
