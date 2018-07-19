# frozen_string_literal: true

require 'evented/version'
require 'ostruct'

# foo
module Evented

  # foo
  class Event < OpenStruct
    # include Util::WithReaders
    # attr_reader :entity_class, :entity_id, :entity_version, :event_type, :event_args, :event_kwds
  end

  module EventSourced
    attr_reader :entity_id, :entity_version
    def emit(event_type, **payload)
      # placeholder method that will be replaced by a singleton method
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength
    def self.included(base)
      class_methods = Module.new do
        event_handlers = {}

        handle_event = lambda { |event_type, *args, **kwds|
          handler = event_handlers[event_type]
          instance_exec(*args, **kwds, &handler) if handler
          @entity_version += 1
        }

        define_method(:on) do |event_type, &block|
          event_handlers[event_type] = block
        end

        define_method(:load) do |id, event_journal|
          entity = new

          entity.instance_eval do
            @entity_version = 0
            @entity_id = id
          end

          event_journal.load_events(entity.class, id, entity.entity_version + 1) do |event|
            entity.instance_exec(
              event.event_type, event.event_args, event.event_kwds, &handle_event
            )
          end

          entity.define_singleton_method(:emit) do |event_type, *args, **kwds|
            instance_exec(event_type, *args, **kwds, &handle_event)
            evt = Event.new(
              entity_class: self.class,
              entity_id: @entity_id,
              entity_version: @entity_version,
              event_type: event_type,
              event_args: args,
              event_kwds: kwds
            ).freeze
            event_journal.store_event!(evt)
            evt
          end
          class << entity
            private :emit # rubocop:disable Style/AccessModifierDeclarations
          end
          entity
        end
      end
      base.extend class_methods
      base.private_class_method :new, :load
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength

  class NotEventSourced < RuntimeError
    def initialize(klass)
      super("The class #{klass} does not include EventSourced")
    end
  end

  module EventJournal
    def load(klass, id)
      raise NotEventSourced.new(klass) unless klass.include? EventSourced
      klass.send :load, id, self
    end
  end
end
