Template.ticketChangelogItem.helpers
  internalNoteClass: ->
    if @internal then 'internal-note'
  changeIsType: (type) ->
    @type is type
  fieldIs: (field) ->
    @field is field
  note: ->
    if this.type is "note" then return true else return false
  file: ->
    FileRegistry.findOne {_id: this.valueOf()}
  noteParagraph: ->
    @message.split('\n')

Template.ticketChangelogItem.events
  'click a[data-action=showAttachmentModal]': (e, tpl) ->
    Iron.query.set 'attachmentId', @valueOf()
