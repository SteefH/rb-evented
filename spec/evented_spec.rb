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

RSpec.describe Evented do
  # it 'has a version number' do
  #   expect(Evented::VERSION).not_to be nil
  # end

  # it 'does something useful' do
  #   expect(false).to eq(true)
  # end

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
    # expect(e.at).to eq('now')
  end
end
