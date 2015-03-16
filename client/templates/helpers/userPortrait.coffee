Template.userPortrait.helpers
  username: -> Meteor.users.findOne({_id: this.valueOf()}).username
