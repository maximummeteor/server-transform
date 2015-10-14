packageSettings =
  name: 'ServerTransform'
  mixins: ['logging']

ServerTransform = class ServerTransform extends PackageBase packageSettings
  @applyTransformations: (transformations = [], docs...) ->
    doc = docs[0]
    for fn in transformations
      doc = fn.apply this, docs
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

  @transformedPublication: (publication, cursor, parentDocs...) ->
    return unless cursor?
    collectionName = cursor._cursorDescription.collectionName
    collection = Mongo.Collection.get collectionName
    transform = (doc) =>
      transforms = collection?._serverTransformations or []
      transforms = transforms.concat (cursor?._serverTransformations or [])
      docs = [doc].concat parentDocs

      doc = @applyTransformations.apply this, [transforms].concat docs
      doc = @transformSubCursors.apply this, [publication].concat docs
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

      computations[doc._id].onInvalidate ->
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

  @transformSubCursors: (publication, obj, parentDocs...) ->
    docs = [obj].concat parentDocs
    for key, cursor of obj when cursor?._cursorDescription?
      @transformedPublication.apply this, [publication, cursor].concat docs
      delete obj[key]
    return obj
