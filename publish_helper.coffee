class @DocumentRefCounter
  constructor: (observer) ->
    @heap = {}
    @observer = observer

  increment: (collectionName, docId) ->
    key = collectionName + ':' + docId.valueOf()
    if !@heap[key]
      @heap[key] = 0
    @heap[key]++

  decrement: (collectionName, docId) ->
    key = collectionName + ':' + docId.valueOf()
    if @heap[key]
      @heap[key]--
      @observer.onChange collectionName, docId, @heap[key]

class @PublishHelper
  constructor: (meteorSub) ->
    @meteorSub = meteorSub
    @docHash = {}
    @refCounter = new DocumentRefCounter
      onChange: (collectionName, docId, refCount) =>
        ServerTransform.log ['Subscription.refCounter.onChange', collectionName + ':' + docId.valueOf() + ' ' + refCount]
        return unless refCount <= 0

        meteorSub.removed collectionName, docId
        @_removeDocHash collectionName, docId
  onStop: (callback) ->
    @meteorSub.onStop callback

  added: (collectionName, docId, doc) ->
    @refCounter.increment collectionName, docId
    return unless @_hasDocChanged(collectionName, docId, doc)

    ServerTransform.log ['Subscription.added', collectionName + ':' + docId]
    @meteorSub.added collectionName, docId, doc
    @_addDocHash collectionName, _.clone doc

  changed: (collectionName, id, doc) ->
    return unless @_isDocPublished(collectionName, id)
    changes = @_computeChanges collectionName, id, doc
    return if _.isEmpty changes

    ServerTransform.log ['Subscription.changed', collectionName + ':' + id]
    @meteorSub.changed collectionName, id, changes
    @_updateDocHash collectionName, id, changes

  removed: (collectionName, id) ->
    ServerTransform.log ['Subscription.removed', collectionName + ':' + id.valueOf()]
    @refCounter.decrement collectionName, id

  _computeChanges: (collectionName, id, doc) ->
    existingDoc = @docHash[@_buildHashKey(collectionName, id)]
    return doc unless existingDoc
    changes = {}

    for i of doc when doc.hasOwnProperty(i) and !_.isEqual(doc[i], existingDoc[i])
      changes[i] = doc[i]
    return changes

  _addDocHash: (collectionName, doc) ->
    @docHash[@_buildHashKey(collectionName, doc._id)] = doc

  _updateDocHash: (collectionName, id, changes) ->
    key = @_buildHashKey(collectionName, id)
    existingDoc = @docHash[key] or {}
    @docHash[key] = _.extend(existingDoc, changes)

  _isDocPublished: (collectionName, id) ->
    key = @_buildHashKey(collectionName, id)
    !!@docHash[key]

  _hasDocChanged: (collectionName, id, doc) ->
    existingDoc = @docHash[@_buildHashKey(collectionName, id)]
    return true unless existingDoc
    for i of doc
      return true if doc.hasOwnProperty(i) and !_.isEqual(doc[i], existingDoc[i])
    return false

  _removeDocHash: (collectionName, id) ->
    key = @_buildHashKey(collectionName, id)
    delete @docHash[key]

  _buildHashKey: (collectionName, id) ->
    collectionName + '::' + id.valueOf()
