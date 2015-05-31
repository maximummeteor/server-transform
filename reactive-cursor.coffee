initialized = false

Meteor.addCollectionExtension (name, options) ->
  return if initialized
  initialized = true
  Cursor = Object.getPrototypeOf(@find {_id: null}).constructor

  originalCursor = ServerTransform._utils.extendFunctions Cursor.prototype,
    observeChanges: (callbacks) ->
      handle = Tracker.nonreactive => originalCursor.observeChanges @, callbacks
      if Tracker.active and @_cursorDescription.options.reactive
        Tracker.onInvalidate ->
          handle.stop()
      handle

    _depend: (changers) ->
      if Tracker.active
        v = new Tracker.Dependency
        v.depend()
        ready = false

        notifyChange = Meteor.bindEnvironment ->
          if ready
            v.changed()

        options = {}
        types = ['added', 'changed', 'removed', 'addedBefore', 'movedBefore']
        _.each types, (fnName) ->
          if changers[fnName]
            options[fnName] = notifyChange

        @observeChanges(options)

        ready = true

    forEach: (args...) ->
      if @_cursorDescription.options.reactive
        @_depend {added: true, changed: true, removed: true}
      originalCursor.forEach @, args...

    map: (args...) ->
      if @_cursorDescription.options.reactive
        @_depend {added: true, changed: true, removed: true}
      originalCursor.map @, args...

    fetch: (args...) ->
      if @_cursorDescription.options.reactive
        @_depend {added: true, changed: true, removed: true}
      originalCursor.fetch @, args...

    count: (args...) ->
      if @_cursorDescription.options.reactive
        @_depend {added: true, removed: true}
      originalCursor.count @, args...
