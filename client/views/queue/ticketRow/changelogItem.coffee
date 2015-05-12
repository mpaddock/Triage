Template.changelogItem.helpers
  changeIsType: (type) ->
    @type is type
  note: ->
    if this.type is "note" then return true else return false
