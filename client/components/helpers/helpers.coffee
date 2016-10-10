UI.registerHelper 'usernameFromId', (userId) ->
  Meteor.users.findOne(userId)?.username

UI.registerHelper 'isCordova', ->
  Meteor.isCordova

UI.registerHelper 'arrayify', (obj) ->
  #Transforms objects with k/v pairs into arrays of objects so Handlebars can iterate over them properly.
  result = []
  for k,v of obj
    result.push {
      name: k
      value: v
    }
  return result

UI.registerHelper 'linkify', (text) ->
  # URLs starting with http://, https://, or ftp://
  
  {escapeString} = require '/imports/util/escapeString.coffee'
  text = escapeString(text)

  urlPattern = /(\b(https?|ftp):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gim
  pseudoUrlPattern = /(^|[^\/])(www\.[-A-Z0-9+&@#\/%=~_|.]*[-A-Z0-9+&@#\/%=~_|])/gim
  emailAddressPattern = /[\w.]+@[a-zA-Z_-]+?(?:\.[a-zA-Z]{2,6})+/gim

  replacedText = text
            .replace(urlPattern, '<a href="$&" target="_blank">$&</a>')
            .replace(pseudoUrlPattern, '$1<a href="http://$2" target="_blank">$2</a>')
            .replace(emailAddressPattern, '<a href="mailto:$&">$&</a>')
 
  return Spacebars.SafeString replacedText

UI.registerHelper 'tokenSettings', ->
  {
    position: "bottom"
    limit: 5
    rules: [
      {
        token: '@'
        collection: Meteor.users
        field: 'username'
        template: Template.userPill
        selector: (match) ->
          r = new RegExp match, 'i'
          return { $or: [ { username: r }, { displayName: r } ] }
      }
      {
        token: '#'
        collection: Tags
        field: 'name'
        template: Template.tagPill
        noMatchTemplate: Template.noMatchTagPill
      }
      {
        token: 'status:'
        collection: Statuses
        field: 'name'
        template: Template.statusPill
        noMatchTemplate: Template.noMatchStatusPill
      }
    ]
  }

UI.registerHelper 'userSettings', ->
  {
    position: "top"
    limit: 5
    rules: [
      collection: Meteor.users
      field: 'username'
      template: Template.userPill
      noMatchTemplate: Template.noMatchUserPill
      selector: (match) ->
        r = new RegExp match, 'i'
        return { $or: [ { username: r }, { displayName: r } ] }
    ]
  }

UI.registerHelper 'userSettingsBottom', ->
  {
    position: "bottom"
    limit: 5
    rules: [
      collection: Meteor.users
      field: 'username'
      template: Template.userPill
      noMatchTemplate: Template.noMatchUserPill
      selector: (match) ->
        r = new RegExp match, 'i'
        return { $or: [ { username: r }, { displayName: r } ] }
    ]
  }
UI.registerHelper 'tagSettings', ->
  {
    position: "top"
    limit: 5
    rules: [
      collection: Tags
      field: 'name'
      template: Template.tagPill
      noMatchTemplate: Template.noMatchTagPill
    ]
  }

{Parsers} = require '/imports/util/parsers.coffee'
@Parsers = Parsers

