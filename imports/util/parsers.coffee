@Parsers = {}

#Scans a body of text for hashtags (#hashtag), returns an array of unique results.
@Parsers.getTags = (text) ->
  _.uniq text.match(/\B#[a-zA-Z0-9-_/]+\b/g) # normal word characters plus hyphens and slashes
    .filter (x) ->
      # Filter if matching a 3 or 6-digit hex code, e.g. #a0a0a0 or #fff
      not /((#[a-fA-F0-9]{3})(\W|$)|(#[a-fA-F0-9]{6})(\W|$))/g.test(x)
    .map (x) ->
      # Strip out hash
      x.replace('#', '')

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


@Parsers = @Parsers || {}
@Parsers.prepareContentForEmail = (content) ->
  # Input:
  #   content (String) - A string to be sanitized and split into paragraphs.
  # Output: 
  #   Sanitized, separated string.
  #
  paragraphs = content.split('\n')
  newContent = ""
  {escapeString} = require './escapeString.coffee'
  _.each paragraphs, (p) ->
    newContent = newContent +
      "<p>#{escapeString(p)}</p>"
  return newContent

exports.Parsers = @Parsers

