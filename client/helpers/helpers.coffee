Handlebars.registerHelper 'arrayify', (obj) ->
  #Transforms objects with k/v pairs into arrays of objects so Handlebars can iterate over them properly.
  result = []
  for k,v of obj
    result.push {
      name: k
      value: v
    }
  return result

(exports ? this).getMediaFunctions = ->
  requiredFunctions = ['pickLocalFile', 'capturePhoto', 'captureAudio', 'captureVideo']
  if Meteor.isCordova
    CordovaMedia
  else
    WebMedia

#Scans a body of text for hashtags (#hashtag), returns an array of unique results.
(exports ? this).getTags = (text) ->
  _.uniq text.match(/#\S+/g)

#Scans a body of text for user tags (@username), and then searches Meteor.users by username and returns an array of unique userIds.
(exports ? this).getUsers = (text) ->
  usertags = text.match(/\@\S+/g)
  users = []
  _.each usertags, (username) ->
    userId = Meteor.users.findOne({username: username.substring(1)})?._id
    if userId then users.push(userId)
  return _.uniq users
