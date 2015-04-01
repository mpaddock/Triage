Template.userPortrait.helpers
  user: ->
    console.log this.userId
    return Meteor.users.findOne({_id: this.userId})
