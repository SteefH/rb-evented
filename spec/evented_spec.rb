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

  def eat(number_of_slices = 1)
    number_of_slices_that_can_be_eaten = [number_of_slices, @number_of_slices].min
    emit(:eaten, number_of_slices_that_can_be_eaten) if number_of_slices_that_can_be_eaten > 0
  end

  def refill(number_of_slices)
    emit(:refill, number_of_slices)
  end

  on(:eaten) do |number_of_slices|
    @number_of_slices -= number_of_slices
  end

  on(:refill) do |number_of_slices|
    @number_of_slices += number_of_slices
  end
end

RSpec.describe Evented do
  it 'creates events' do
    c = CoffeeMug.load(1)
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
    bb = BreadBox.load(1)

    # expect(e.at).to eq('now')
  end
end
