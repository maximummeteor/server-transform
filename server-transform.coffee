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
      ServerTransform.log 'Publication started'
      publishHelper = new PublishHelper(this)

      for cursor in cursors
        ServerTransform.transformedPublication publishHelper, cursor

      @onStop ->
        publishHelper = null

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
      start = ->
        computations[doc._id] = Tracker.autorun ->
          ServerTransform.log "autorun: #{collectionName}:#{doc._id}"
          publication.changed collectionName, doc._id, transform(doc)
        ServerTransform.log "Tracking started: #{collectionName}:#{doc._id}"

      return start() unless computations[doc._id]?
      return start() unless computations[doc._id].invalidated

      computation.onInvalidate ->
        Tracker.afterFlush ->
          computations[doc._id].stop()
          ServerTransform.log "Tracking stopped: #{collectionName}:#{doc._id}"
          start()

    handles = []

    handles.push cursor.observeChanges
      changed: (id, fields) ->
        publication.changed collectionName, id, fields

    handles.push cursor.observe
      added: (doc) ->
        publication.added collectionName, doc._id, transform(doc)
        startTracking doc
      changed: (doc) ->
        startTracking doc
      removed: (doc) ->
        publication.removed collectionName, doc._id
        return unless computations[doc._id]?
        computations[doc._id].stop()
        delete computations[doc._id]

    publication.onStop ->
      handle?.stop() for handle in handles
      for key, computation in computations
        computation.stop()
      ServerTransform.log 'Publication stopped'

  @transformSubCursors: (publication, obj) ->
    for key, cursor of obj when cursor?._cursorDescription?
      @transformedPublication publication, cursor
      delete obj[key]
    return obj
