Template.attachmentModal.helpers
  attachment: ->
    return FileRegistry.findOne @attachmentId
  fileIsImage: ->
    _.contains [ 'jpg', 'jpeg', 'gif', 'bmp', 'png' ], @filename.substr(@filename.indexOf('.')+1)
  fileIsPdf: ->
    @filename.substr(@filename.indexOf('.')+1) is 'pdf'

Template.attachmentModal.events
  'hidden.bs.modal': (e, tpl) ->
    Iron.query.set 'attachmentId', null
    Blaze.remove tpl.view
