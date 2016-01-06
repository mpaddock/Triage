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
  
  text = escape(text)

  urlPattern = /\b(?:https?|ftp):\/\/[a-z0-9-+&@#\/%?=~_|!:,.;]*[a-z0-9-+&@#\/%=~_|]/gim
  pseudoUrlPattern = /(^|[^\/])(www\.[\S]+(\b|$))/gim
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



@Parsers = {}
#Scans a body of text for hashtags (#hashtag), returns an array of unique results.
@Parsers.getTags = (text) ->
  _.uniq(text.match(/\B#\S+\b/g)).map (x) ->
    x.replace('#', '') #Strip out hash

#Scans a body of text for user tags (@username), and then searches Meteor.users by username and returns an array of unique userIds.
@Parsers.getUserIds = (text) ->
  usertags = text.match(/\B\@\S+\b/g) || []
  users = []
  _.each usertags, (username) ->
    userId = Meteor.users.findOne({username: username.substring(1)})?._id
    if userId then users.push(userId)
  return _.uniq users

@Parsers.getUsernames = (text) ->
  usernames = text.match(/\B\@\S+\b/g) || []
  return usernames.map (x) ->
    x.replace('@', '')

@Parsers.getStatuses = (text) ->
  _.uniq(text.match(/status:(\w+-\w+|\w+|"[^"]*"+|'[^']*')/g)).map (x) ->
    x.replace('status:', '').replace(/"/g, '').replace(/'/g, '') #strip status: and all quotes.

@Parsers.validateEmail = (email) ->
  /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(email)

@Parsers.getTerms = (text) ->
  # Gets separate terms that do NOT match the other tokens.
  terms = text.match /"[^"]*"|status:(\w+-\w+|\w+|"[^"]*"+|'[^']*')|\#\S+|\@\S+|[^\s]+/g
  _.difference terms, text.match(/status:(\w+-\w+|\w+|"[^"]*"+|'[^']*')|#\S+|\@\S+/g)
