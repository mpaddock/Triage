Template.ticketNoteArea.helpers
  changelog: ->
    items = Changelog.find {ticketId: @_id}, {sort: timestamp: 1}
    return { items: items, count: items.count() }

  queueMember: -> Meteor.user().isQueueMemberById(@queueId)
