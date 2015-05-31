Meteor.publishTransformed = ServerTransform.getInstance().publishTransformed

Mongo.Collection::serverTransform = (definition) ->
  @_serverTransformations = [] unless @_serverTransformations?
  if typeof definition is 'function'
    @_serverTransformations.push definition
  else
    @_serverTransformations.push (doc) ->
      for name, prop of definition
        if typeof prop is 'function'
          doc[name] = prop.call this, doc
        else
          doc[name] = prop
      return doc

initialized = false
Meteor.addCollectionExtension (name, options) ->
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
      @_serverTransformations.push (doc) ->
        for name, prop of definition
          if typeof prop is 'function'
            doc[name] = prop.call this, doc
          else
            doc[name] = prop
        return doc

    return this
