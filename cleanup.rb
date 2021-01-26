#!/usr/bin/env ruby
require 'strscan'
require 'csv'


class ChatLine < Struct.new(:timestamp, :speaker, :text)
  def first_name
    speaker.gsub(/☀️ /, "☀️").gsub(/^\*+/, '').gsub(/^London - /, '').split(" ")[0]
  end
end

class ZoomChatLogParser
  attr_reader :file

  def initialize(file)
    @file = file
  end

  def lines
    Enumerator.new do |y|
      s = StringScanner.new(File.read(file, mode:"r:UTF-8"))

      begin
        timestamp = s.scan(/^[0-9]{2}:[0-9]{2}:[0-9]{2}/)
        s.skip(/\s+/)
        s.scan(/From (.*?) : /)
        speaker = s[1]
        text = s.scan_until(/^[0-9]{2}:[0-9]{2}:[0-9]{2}/)
        if text
          text = text[0...-s.matched_size].chomp
          s.pos = s.pos-s.matched_size
        else
          text = s.rest
          s.terminate
        end
        y << ChatLine.new(timestamp, speaker, text)
      end until s.eos?
    end
  end
end

unless ARGV.size > 0
  $stderr.puts "USAGE: #{__FILE__} <chatlog file>"


  exit 1


end

ZoomChatLogParser.new(ARGV[0]).lines.reject {|l| l.speaker =~ /Privately|Direct Message/}.each do |l|
  puts [l.timestamp, l.first_name, l.text].to_csv
end
