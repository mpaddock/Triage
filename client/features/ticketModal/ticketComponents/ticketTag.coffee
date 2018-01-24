Template.removeAttachmentModal.helpers
  attachment: -> FileRegistry.findOne(@attachmentId)
  ticket: -> Tickets.findOne(@ticketId)

Template.removeAttachmentModal.events
  'click button[data-action=removeAttachment]': (e, tpl) ->
    Tickets.update @ticketId, {$pull: {attachmentIds: @attachmentId}}
    $('#removeAttachmentModal').modal('hide')

  'show.bs.modal': (e, tpl) ->
    zIndex = 1040 + ( 10 * $('.modal:visible').length)
    $(e.target).css('z-index', zIndex)
    setTimeout ->
      $('.modal-backdrop').not('.modal-stack').css('z-index', zIndex - 1).addClass('modal-stack')
    , 0

  'hidden.bs.modal': (e, tpl) ->
    Blaze.remove tpl.view
    if $('.modal:visible').length
      $('body').addClass('modal-open')

  
Template.ticketTag.events
  'click a[data-action=removeTag]': (e, tpl) ->
    e.preventDefault()
    ticketId = Template.parentData(1)._id
    Tickets.update {_id: ticketId}, {$pull: {tags: this.valueOf()}}
  
  'click a[data-action=addTagFilter]': (e, tpl) ->
    e.preventDefault()
    value = this.valueOf()
    filter = Iron.query.get('tag')?.split(',') || []
    unless filter.indexOf(value) > -1
      filter.push(value)
    Iron.query.set 'tag', filter.join()


