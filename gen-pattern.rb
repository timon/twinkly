#!/usr/bin/env ruby

require "json"

LEDS = 56

BLACK = [0, 0, 0]

COLOR_MAP = [
  [0xFF, 0, 0], [0, 0xFF, 0], [0, 0, 0xFF],
  [0, 0xFF, 0xFF], [0xFF, 0, 0xFF], [0xFF, 0xFF, 0],
  [0xFF, 0xFF, 0xFF], [0x7F, 0x7F, 0xFF]
].freeze

class Frame
  def initialize(leds: LEDS, fill: BLACK)
    @pixels = Array.new(leds, fill)
  end

  def [](i)
    @pixels[i]
  end

  def []=(i, v)
    @pixels[i] = v
  end

  def to_s
    @pixels.map(&method(:to_rgb)).join
  end

  def to_rgb(pixel)
    pixel.pack("C*").force_encoding("ASCII-8BIT")
  end
end

@frames = []
@tails = []
@queue = []

def run_led(margin, color)
  (LEDS - margin).times do |step|
    frame = single_led step, color
    frame[LEDS - @tails.length..-1] = @tails
    @frames.push frame.to_s
  end

  @tails.unshift color

  @frames
end

def run_queue
  counter = 0
  leds = 0

  loop do
    changed = false
    @queue.each do |dot|
      # Don't use ||= because it will skip move_dot invocation on second pass
      changed = move_dot(dot) || changed
    end

    if counter % 3 == 0 && (@queue.empty? || @queue.last[:pos] != 0)
      @queue.push index: leds, pos: 0, color: COLOR_MAP[leds % COLOR_MAP.size]
      leds += 1
      changed = true
    end

    break unless changed

    frame = Frame.new
    @queue.each { |pos:, color:, index:| frame[pos] = color }
    @frames.push frame

    counter += 1
  end
end

def move_dot(dot)
  max_pos = LEDS - dot[:index] - 1
  return false if dot[:pos] >= max_pos

  dot[:pos] += 1
end

def single_led(index, color)
  frame = Frame.new
  frame[index] = color
  frame
end

def fill(color)
  @frames.push Frame.new fill: color
end

def write_frames(file = "pattern", delay: 0.25)
  meta = {
    frame_delay: (delay * 1000).to_i,
    leds_number: LEDS,
    frames_number: @frames.size
  }

  File.open("#{file}.bin", "w:ascii-8bit") { |f| f.write @frames.join }
  File.open("#{file}.json", "w") { |f| f.write meta.to_json }
end

def main
  # 56.times do |i|
  #   run_led i, COLOR_MAP[i % COLOR_MAP.size]
  # end

  run_queue

  5.times do |i|
    fill COLOR_MAP[i.even? ? -2 : -1]
  end

  10.times do
    fill BLACK
  end
end

