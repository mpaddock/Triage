Template.tag.events
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
