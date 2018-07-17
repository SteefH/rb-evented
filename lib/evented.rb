# frozen_string_literal: true

require 'evented/version'

# foo
module Evented
  # foo
  class Event
    attr_reader :event_type, :payload

    def initialize(event_type, **payload)
      @event_type = event_type
      @payload = payload
    end
  end

  # Mixin for making a class event sourced
  module EventSourced
    attr_reader :entity_id

    def self.included(base)
      base.send :include, InstanceMethods
      base.extend ClassMethods
      base.private_class_method :new
    end

    module InstanceMethods
      def emit(event_type, **payload)
        e = Event.new(event_type, **payload)
        send("#{self.class}_on_#{event_type}", payload)
        # @entity_version ||= 0
        @entity_version += 1
        e
      end

      # def entity_version
      #   @entity_version ||= 0
      # end
    end

    module ClassMethods
      # instance_eval { private_class_method :new }

      def on(event_type, &block)
        define_method("#{self}_on_#{event_type}") { |payload| instance_exec(payload, &block) }
      end

      def load(id, _load_events = nil, _load_snapshot = nil)
        i = new
        i.instance_eval { @entity_id = id; @entity_version = 0 }
        i
      end
    end
  end
end
