module.exports = ->
    class model
        @attrs: []
        @defaults: {}

        @attr: (name, opts) ->
            @attrs.push name

            if opts?.default
                @defaults[name] = opts.default

            return @

        constructor: (data) ->
            props = {}

            for attr in @constructor.attrs
                do (attr) =>
                    _value = data[attr] or @constructor.defaults[attr]
                    _arrayObserveCallback = (changes) =>
                        for change in changes
                            continue unless change.type is 'splice'

                            for i in [change.index ... change.index+change.addedCount]
                                for observer in @_getArrayObserversForAttribute attr, 'add'
                                    observer change.object[i], i

                            for removed in change.removed
                                for observer in @_getArrayObserversForAttribute attr, 'remove'
                                    observer removed

                    _observeIfArray = ->
                        if Object.prototype.toString.call(_value) is '[object Array]'
                            Array.observe _value, _arrayObserveCallback

                    _observeIfArray()

                    props[attr] =
                        enumerable: true
                        get: ->
                            return _value
                        set: (value) ->
                            Object.getNotifier(@).notify
                                type: 'update'
                                name: attr
                                oldValue: _value

                            if Object.prototype.toString.call(_value) is '[object Array]'
                                Array.unobserve _value, _arrayObserveCallback

                            _value = value
                            _observeIfArray()

                            return

            Object.defineProperties @, props

        _getArrayObserversForAttribute: (attr, type) ->
            @_arrayObservers ?= {}
            @_arrayObservers[attr] ?= {}
            @_arrayObservers[attr][type] ?= []

            return @_arrayObservers[attr][type]

        on: (event, cb) ->
            match = /^(\S+):(\S+)$/.exec event
            if match
                if match[2] in ['add', 'remove']
                    @_getArrayObserversForAttribute(match[1], match[2]).push cb
                    return
                else if match[2] in ['update']
                    Object.observe @, (changes) ->
                        for change in changes
                            if event is "#{change.name}:#{change.type}"
                                cb @[change.name]
                                return