# frozen_string_literal: true

require 'evented/version'

# foo
module Evented
  # foo
  class Event
    attr_reader :entity_class, :entity_id, :entity_version, :event_type, :payload

    def initialize(entity_class, entity_id, entity_version, event_type, payload)
      @entity_class = entity_class
      @entity_id = entity_id
      @entity_version = entity_version
      @event_type = event_type
      @payload = payload
    end
  end

  # Mixin for making a class event sourced
  module EventSourced
    def self.included(base)
      base.include InstanceMethods
      base.extend ClassMethods
      base.private_class_method :new, :create_new_entity, :load_snapshot
      base.send(:private, :handle_event)
    end

    module InstanceMethods # rubocop:disable Style/Documentation
      attr_reader :entity_id, :entity_version

      def handle_event(handlers, event_type, event_payload)
        handler = handlers[event_type]
        instance_exec event_payload, &handler if handler
        @entity_version += 1
        Event.new(self.class, @entity_id, @entity_version, event_type, event_payload)
      end
    end

    module ClassMethods # rubocop:disable Style/Documentation
      def on(event_type, &block)
        event_handlers[event_type] = block
      end

      def load(id, event_journal, snapshot_store = nil)
        entity = create_new_entity(id, event_journal)
        entity = load_snapshot(entity, snapshot_store) if snapshot_store
        handlers = event_handlers
        event_journal.load_events(entity.class, id, entity.entity_version + 1) do |event|
          entity.send(:handle_event, handlers, event.event_type, event.payload)
        end
        entity
      end

      private

      def event_handlers
        @event_handlers ||= {}
      end

      def create_new_entity(id, event_journal)
        i = new
        handlers = event_handlers
        i.instance_eval { @entity_id = id; @entity_version = 0; }
        i.define_singleton_method(:emit) do |event_type, payload = nil|
          evt = i.send(:handle_event, handlers, event_type, payload)
          event_journal.store_event!(evt)
          evt
        end
        class << i
          private :emit
        end
        i
      end

      def load_snapshot(entity, snapshot_store)
        return entity unless entity.respond_to?(:apply_snapshot!)
        snapshot = snapshot_store.load_snapshot(entity.class, entity.entity_id)
        entity.apply_snapshot!(snapshot)
        entity.instance_eval { @entity_version = snapshot.version }
        entity
      end
    end
  end
end
