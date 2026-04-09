#!/usr/bin/env ruby
# debug_frameit.rb
# Usage: bundle exec ruby tools/debug_frameit.rb /path/to/screenshots_folder

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'json'
require 'pathname'
require_relative '../lib/frameit/module'
require_relative '../lib/frameit/device'
require_relative '../lib/frameit/device_types'
require_relative '../lib/frameit/screenshot'
require_relative '../lib/frameit/template_finder'
require_relative '../lib/frameit/offsets'
require 'fastimage'

include Frameit

screens_dir = ARGV[0] || './'
puts "Scanning screenshots in: #{screens_dir}"

Dir[File.join(screens_dir, '**', '*.png')].each do |path|
  begin
    puts "\n--- #{path} ---"
    size = FastImage.size(path)
    puts "Size: #{size.inspect}"
    # Minimal config
    config = {}
    screenshot = Frameit::Screenshot.new(path, nil, config, nil)
    puts "Detected device: #{screenshot.device&.formatted_name} (id: #{screenshot.device&.id})"
    puts "Device default color: #{screenshot.default_color.inspect}"
    puts "Orientation name: #{screenshot.orientation_name}, frame_orientation: #{screenshot.frame_orientation}"
    template = Frameit::TemplateFinder.get_template(screenshot)
    puts "Template path: #{template.inspect}"
    begin
      offset = Frameit::Offsets.image_offset(screenshot)
      puts "Offset found: #{offset.inspect}"
      # Calculate multiplicator and expected frame resize
      screenshot_width = screenshot.portrait? ? screenshot.size[0] : screenshot.size[1]
      width_in_offset = (offset && offset['width']) ? offset['width'].to_f : nil
      if width_in_offset && width_in_offset > 0
        multiplicator = screenshot_width.to_f / width_in_offset
        puts "screenshot_width=#{screenshot_width}, offset_width=#{width_in_offset}, multiplicator=#{multiplicator}"
      end
    rescue => e
      puts "Offsets lookup error: #{e}"
    end
  rescue => e
    puts "Error processing #{path}: #{e.class}: #{e.message}"
    puts e.backtrace.join("\n")
  end
end
