test1 = 'hello @mdpadd2 this is a test #search status:"kljasd"'
test2 = "@vrang2"

tagsTest1 = "#tag/with/slash #tag-with-hyphen #tag_with_underscore" # tags with special characters
tagsTest2 = "#fff #000 #abc #f1f1f1 #f1f1 #f1f1f1wordafter" #hex codes and hex code similar tags
tagsTest3 = "waggle# waggle#test #test" #middle of word tags

content1 = "This is now done.\nThanks,\nPerson"
result1  = "<p>This is now done.</p><p>Thanks,</p><p>Person</p>"

content2 = "There are < 2 reasons to use < in place of 'less than' in a sentence.\nBut I did it anyway, because this is a test."
result2 = "<p>There are &lt; 2 reasons to use &lt; in place of &#x27;less than&#x27; in a sentence.</p>" +
  "<p>But I did it anyway, because this is a test.</p>"

if Meteor.isClient
  Tinytest.add 'Parsers - usernames and statuses', (test) ->
    test.equal Parsers.getTerms(test1), ['hello', 'this', 'is', 'a', 'test']
    test.equal Parsers.getUsernames(test1), ['mdpadd2']
    test.equal Parsers.getStatuses(test1), ['kljasd']

    test.equal Parsers.getTerms(test2), []
    test.equal Parsers.getUsernames(test2), ['vrang2']

  Tinytest.add 'Parsers - hashtags and hex codes', (test) ->

    test.equal Parsers.getTags(tagsTest1), [ 'tag/with/slash', 'tag-with-hyphen', 'tag_with_underscore' ]
    test.equal Parsers.getTags(tagsTest2), [ 'f1f1', 'f1f1f1wordafter' ]
    test.equal Parsers.getTags(tagsTest3), [ 'test' ]


if Meteor.isServer
  Tinytest.add 'Parsers - email content parsing on server', (test) ->
    test.equal Parsers.prepareContentForEmail(content1), result1
    test.equal Parsers.prepareContentForEmail(content2), result2
