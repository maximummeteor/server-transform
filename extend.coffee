Meteor.publishTransformed = ServerTransform.publishTransformed

definitionTransform = (definition) -> (docs...) ->
  doc = docs[0]
  for name, prop of definition
    if typeof prop is 'function'
      doc[name] = prop.apply this, docs
    else
      doc[name] = prop
  return doc

Mongo.Collection::serverTransform = (definition) ->
  @_serverTransformations = [] unless @_serverTransformations?
  if typeof definition is 'function'
    @_serverTransformations.push definition
  else
    @_serverTransformations.push definitionTransform definition

initialized = false
CollectionExtensions.addExtension (name, options) ->
  return if initialized
  initialized = true
  Cursor = Object.getPrototypeOf(@find {_id: null}).constructor
  Cursor::serverTransform = (definition) ->
    @options = @options or {}
    @options.reactive = true

    @_serverTransformations = [] unless @_serverTransformations?

    if typeof definition is 'function'
      @_serverTransformations.push definition
    else
      @_serverTransformations.push definitionTransform definition

    return this
