Handlebars.registerHelper 'arrayify', (obj) ->
  #Transforms objects with k/v pairs into arrays of objects so Handlebars can iterate over them properly.
  result = []
  for k,v of obj
    result.push {
      name: k
      value: v
    }
  return result

#Scans a body of text for hashtags (#hashtag), returns an array of unique results.
(exports ? this).getTags = (text) ->
  _.uniq(text.match(/#\S+/g)).map (x) ->
    x.replace('#', '') #Strip out hash

#Scans a body of text for user tags (@username), and then searches Meteor.users by username and returns an array of unique userIds.
(exports ? this).getUserIds = (text) ->
  usertags = text.match(/\@\S+/g) || []
  users = []
  _.each usertags, (username) ->
    userId = Meteor.users.findOne({username: username.substring(1)})?._id
    if userId then users.push(userId)
  return _.uniq users

(exports ? this).getUsernames = (text) ->
  usernames = text.match(/\@\S+/g) || []
  return usernames.map (x) ->
    x.replace('@', '')

(exports ? this).getStatuses = (text) ->
  _.uniq(text.match(/status:(\w+|"[^"]*"+|'[^']*')/g)).map (x) ->
    x.replace('status:', '').replace(/"/g, '').replace(/'/g, '') #strip status: and all quotes.
