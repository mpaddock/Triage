test1 = 'hello @mdpadd2 this is a test #search status:"kljasd"'
test2 = "@vrang2"

tagsTest1 = "#tag/with/slash #tag-with-hyphen #tag_with_underscore" # tags with special characters
tagsTest2 = "#fff #000 #abc #f1f1f1 #f1f1 #f1f1f1wordafter" #hex codes and hex code similar tags

Tinytest.add 'Parsers - usernames and statuses', (test) ->
  if Meteor.isClient
    test.equal Parsers.getTerms(test1), ['hello', 'this', 'is', 'a', 'test']
    test.equal Parsers.getUsernames(test1), ['mdpadd2']
    test.equal Parsers.getStatuses(test1), ['kljasd']

    test.equal Parsers.getTerms(test2), []
    test.equal Parsers.getUsernames(test2), ['vrang2']

Tinytest.add 'Parsers - hashtags and hex codes', (test) ->
  if Meteor.isClient
    test.equal Parsers.getTags(tagsTest1), [ 'tag/with/slash', 'tag-with-hyphen', 'tag_with_underscore' ]
    test.equal Parsers.getTags(tagsTest2), [ 'f1f1', 'f1f1f1wordafter' ]
