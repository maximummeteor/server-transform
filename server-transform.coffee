packageSettings =
  name: 'ServerTransform'
  mixins: ['logging']

ServerTransform = class ServerTransform extends PackageBase packageSettings
  @applyTransformations: (transformations, doc) ->
    return doc unless transformations?

    for fn in transformations
      doc = fn doc
    return doc

  @publishTransformed: (name, fn) ->
    Meteor.publish name, ->
      cursors = fn.apply this, arguments
      return @ready() unless cursors?
      cursors = [cursors] unless cursors instanceof Array

      for cursor in cursors
        ServerTransform.transformedPublication this, cursor

      @ready()

  @transformedPublication: (publication, cursor) ->
    return unless cursor?
    collectionName = cursor._cursorDescription.collectionName
    collection = Mongo.Collection.get collectionName
    transform = (doc) =>
      doc = @applyTransformations collection?._serverTransformations, doc
      doc = @applyTransformations cursor?._serverTransformations, doc
      doc = @transformSubCursors publication, doc
      return doc
    computations = {}

    startTracking = (doc) ->
      computations[doc._id].stop() if computations[doc._id]?
      computations[doc._id] = Tracker.autorun ->
        publication.changed collectionName, doc._id, transform(doc)

    handle = cursor.observe
      added: (doc) ->
        publication.added collectionName, doc._id, doc
        startTracking doc
      changed: (doc) ->
        startTracking doc
      removed: (doc) ->
        if computations[doc._id]?
          computations[doc._id].stop()
          delete computations[doc._id]

        publication.removed collectionName, doc._id

    publication.onStop ->
      handle?.stop()
      for key, computation in computations
        computation.stop()

  @transformSubCursors: (publication, obj) ->
    for key, cursor of obj when cursor?._cursorDescription?
      @transformedPublication publication, cursor
      delete obj[key]
    return obj
