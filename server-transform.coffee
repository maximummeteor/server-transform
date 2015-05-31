packageSettings =
  name: 'ServerTransform'
  mixins: ['singleton', 'logging']

ServerTransform = class ServerTransform extends PackageBase packageSettings
  applyTransformations: (transformations, doc) ->
    return doc unless transformations?

    for fn in transformations
      doc = fn doc
    return doc

  publishTransformed: (name, fn) ->
    Meteor.publish name, ->
      cursors = fn.apply this, arguments
      cursors = [cursors] unless cursors instanceof Array

      for cursor in cursors
        ServerTransform.getInstance().transformedPublication this, cursor

      @ready()

  transformedPublication: (publication, cursor) ->
    collectionName = cursor._cursorDescription.collectionName
    collection = Mongo.Collection.get collectionName
    transform = (doc) =>
      doc = @applyTransformations collection?._serverTransformations, doc
      doc = @applyTransformations cursor?._serverTransformations, doc
      return doc
    computation = null

    handle = cursor.observe
      added: (doc) ->
        publication.added collectionName, doc._id, transform(doc)

        computation.stop() if computation?
        computation = Tracker.autorun ->
          publication.changed collectionName, doc._id, transform(doc)

      changed: (doc) ->
        publication.changed collectionName, doc._id, transform(doc)

        computation.stop() if computation?
        computation = Tracker.autorun ->
          publication.changed collectionName, doc._id, transform(doc)

      removed: (doc) ->
        publication.removed collectionName, doc._id

    publication.onStop ->
      handle.stop()
      computation.stop()
