@Parsers = @Parsers || {}
@Parsers.prepareContentForEmail = (content) ->
  # Input:
  #   content (String) - A string to be sanitized and split into paragraphs.
  # Output: 
  #   Sanitized, separated string.
  #
  paragraphs = content.split('\n')
  newContent = ""
  _.each paragraphs, (p) ->
    newContent = newContent +
      "<p>#{escapeString(p)}</p>"
  return newContent


