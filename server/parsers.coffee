@Parsers = @Parsers || {}
@Parsers.prepareContentForEmail = (content) ->
  # Input:
  #   content (String) - A string to be sanitized and split into paragraphs.
  # Output: 
  #   Sanitized, separated string.
  #
  #
  md = new markdownit {
    linkify: true
    breaks: true
  }
  md.disable [ 'image', 'table', 'heading' ]
  md.render(content)
