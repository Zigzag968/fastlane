require_relative 'module'
require_relative 'frame_downloader'

module Frameit
  class Offsets
    # Returns the image offset needed for a certain device type
    def self.image_offset(screenshot)
      require 'json'

      unless @offsets_cache
        offsets_json_path = File.join(FrameDownloader.new.templates_path, "offsets.json")
        UI.user_error!("Could not find offsets.json file at path '#{offsets_json_path}'") unless File.exist?(offsets_json_path)
        @offsets_cache = JSON.parse(File.read(offsets_json_path))
      end

      # Determine which orientation offsets to look for. Use the screenshot's
      # frame orientation (which can be forced via Frameit configuration).
      orientation_key = screenshot.portrait? ? "portrait" : "landscape"

      # Build a list of candidate keys to be resilient against different
      # naming schemes in offsets.json (users may edit these manually).
      candidates = []
      begin
        # prefer the raw formatted name (e.g. "Apple iPad Pro 13-inch (M4)")
        candidates << screenshot.device_name
      rescue StandardError
      end

      # If the Screenshot has a Device object, prefer its formatted_name_without_apple
      if screenshot.respond_to?(:device) && !screenshot.device.nil? && screenshot.device.respond_to?(:formatted_name_without_apple)
        candidates << screenshot.device.formatted_name_without_apple
      end

      # sanitized variant (remove Apple, replace hyphens with spaces)
      candidates << sanitize_device_name(screenshot.device_name)

      # also try variants with/without hyphens
      candidates << screenshot.device_name.gsub('-', ' ') rescue nil
      candidates << screenshot.device_name.gsub(' - ', ' ') rescue nil

      # uniq and compact
      candidates = candidates.compact.map(&:strip).uniq

      offset_value = nil
      tried_keys = []
      candidates.each do |key|
        tried_keys << key
        offset_value = @offsets_cache.dig(orientation_key, key)
        break if offset_value
      end

      unless offset_value
        UI.error("Tried looking for offset information for '#{orientation_key}', #{screenshot.device_name} in '#{offsets_json_path}'")
        UI.error("Keys tried: #{tried_keys.join(', ')}") unless tried_keys.empty?

        # Fallback: try portrait offsets to preserve backward compatibility
        tried_keys = []
        candidates.each do |key|
          tried_keys << key
          offset_value = @offsets_cache.dig("portrait", key)
          break if offset_value
        end

        if offset_value
          UI.important("Falling back to 'portrait' offsets for '#{candidates.first}'")
        else
          UI.error("Could not find offset_information for '#{screenshot.path}'")
        end
      end

      return offset_value
    end

    def self.sanitize_device_name(basename)
      # this should be the same as frames_generator's sanitize_device_name (except stripping colors):
      basename = basename.gsub("Apple", "")
      basename = basename.gsub("-", " ")
      basename.strip.to_s
    end
  end
end
