Meteor.publishTransformed = ServerTransform.getInstance().publishTransformed

Mongo.Collection::serverTransform = (fn) ->
  @_serverTransformations = [] unless @_serverTransformations?
  @_serverTransformations.push fn

Mongo.Collection::computedProperty = (name, fn) ->
  @serverTransform (doc) ->
    doc[name] = fn.call this, doc
    return doc

Mongo.Collection::applyServerTransformation = (doc) ->
  @_serverTransformations = [] unless @_serverTransformations?
  for fn in @_serverTransformations
    doc = fn doc
  return doc
