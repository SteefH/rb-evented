# frozen_string_literal: true

class CoffeeMug
  include Evented::EventSourced

  attr_reader :state

  def initialize
    @state = :empty
  end

  def drink
    puts 'Try drinking my coffee'
    emit(:drunk, at: 'now') if @state == :full
  end

  def refill
    puts 'Try refilling my coffee'
    emit(:refilled) if @state == :empty
  end

  on(:drunk) do |at:, foo: nil|
    puts "Drunk at #{at}, #{foo}"
    @state = :empty
  end

  on(:refilled) do
    puts "Refilled #{self}"
    @state = :full
  end
end

class BreadBox
  include Evented::EventSourced
  attr_reader :number_of_slices

  def initialize
    @number_of_slices = 0
  end

  def take(number_of_slices = 1)
    allowed_number_of_slices = [number_of_slices, @number_of_slices].min
    emit(:slices_taken, allowed_number_of_slices) if allowed_number_of_slices > 0
  end

  def refill(number_of_slices)
    emit(:refilled, number_of_slices)
  end

  on(:slices_taken) do |number_of_slices|
    @number_of_slices -= number_of_slices
  end

  on(:refilled) do |number_of_slices|
    @number_of_slices += number_of_slices
  end
end

class InMemoryJournal
  def initialize
    @events = Hash.new { |by_class,klass|
        by_class[klass] = Hash.new { |by_id,id|
          by_id[id] = [] 
        } 
    }
  end

  def load_events(klass, id, start_version)
    @events[klass][id].each do |evt|
      puts "LOADING #{evt.to_s}"
      yield evt if evt.entity_version >= start_version
    end
  end

  def store_event(evt)
    klass = evt.entity_class
    id = evt.entity_id
    @events[klass][id] << evt
  end
end

RSpec.describe Evented do
  it 'creates events' do
    journal = InMemoryJournal.new
    c = CoffeeMug.load(1, journal)
    expect(c.state).to eq(:empty)
    # expect(c.entity_version).to eq(0)
    expect(c.drink).to eq(nil)
    expect(c.state).to eq(:empty)
    c.refill
    expect(c.state).to eq(:full)
    expect(c.entity_id).to eq(1)
    e = c.drink
    expect(e.event_type).to eq(:drunk)
    expect(e.payload).to eq(at: 'now')
    e = c.refill
    expect(c.state).to eq(:full)
    expect(e.event_type).to eq(:refilled)
    c2 = CoffeeMug.load(1, journal)
    expect(c2.state).to eq(c.state)
    expect(c2.entity_version).to eq(c.entity_version)
    bb = BreadBox.load(1, journal)
    bb.take
    bb.refill 100
    # expect(e.at).to eq('now')
  end
end
