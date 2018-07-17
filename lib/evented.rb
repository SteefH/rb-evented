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
      base.private_class_method :new
    end

    module InstanceMethods # rubocop:disable Style/Documentation
      attr_reader :entity_id

      def emit(event_type, **payload)
        handler = @event_handlers[event_type]
        instance_exec(payload, &handler) if handler
        @entity_version += 1
        Event.new(self.class, @entity_id, @entity_version, event_type, payload)
      end
    end

    module ClassMethods # rubocop:disable Style/Documentation
      def on(event_type, &block)
        (@event_handlers ||= {})[event_type] = block
      end

      def load(id)
        i = new
        event_handlers = @event_handlers
        i.instance_eval do
          @entity_id = id
          @entity_version = 0
          @event_handlers = event_handlers
        end
        i
      end
    end
  end
end
