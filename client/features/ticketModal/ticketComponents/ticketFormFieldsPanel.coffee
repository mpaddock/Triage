Template.ticketFormFieldsPanel.onCreated ->
  this.panelIsCollapsed = new ReactiveVar(true)

Template.ticketFormFieldsPanel.helpers
  collapsed: -> Template.instance().panelIsCollapsed.get()

Template.ticketFormFieldsPanel.events
  'show.bs.collapse': (e, tpl) ->
    tpl.panelIsCollapsed.set false

  'hide.bs.collapse': (e, tpl) ->
    tpl.panelIsCollapsed.set true
