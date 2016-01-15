# from http://github.com/ng/paperclip-watermarking-app
# with modifications from http://exviva.posterous.com/watermarking-images-with-rails-3-and-papercli
# and even more modifications to ensure works with paperclip >= 2.3.8 and rails >= 3
#
# Note: In rails 3 paperclip processors are not automatically loaded.
# You must add the following above your model class definition:
#
# require 'paperclip_processors/watermark'

module Paperclip
  class Watermark < Processor
    # Handles watermarking of images that are uploaded.
    attr_accessor :current_geometry, :target_geometry, :format, :whiny, :convert_options, :watermark_path, :overlay, :position, :style

    def initialize file, options = {}, attachment = nil
      super
      puts "watermark options: #{options}"
      geometry          = options[:geometry]
      @file             = file
      if geometry.present?
        @crop             = geometry[-1,1] == '#'
      end
      @target_geometry  = Geometry.parse geometry
      @current_geometry = Geometry.from_file @file
      @convert_options  = options[:convert_options]
      @whiny            = options[:whiny].nil? ? true : options[:whiny]
      @format           = options[:format]
      @watermark_path   = "#{Rails.root}/public/watermark-images.png" # options[:watermark_path] ? "#{Rails.root}/public/Logo-new.png" : options[:watermark_path]
      @position         = options[:position].nil? ? "SouthEast" : options[:position]
      @overlay          = options[:overlay].nil? ? true : false
      @current_format   = File.extname(@file.path)
      @basename         = File.basename(@file.path, @current_format)
      @style            = options[:style] ? options[:style] : "none"
    end

    # TODO: extend watermark

    # Returns true if the +target_geometry+ is meant to crop.
    def crop?
      @crop
    end

    # Returns true if the image is meant to make use of additional convert options.
    def convert_options?
      not [*@convert_options].reject(&:blank?).empty?
    end

    # Performs the conversion of the +file+ into a watermark. Returns the Tempfile
    # that contains the new image.
    def make
      puts "In watermark with geometry #{target_geometry}, style #{@style}, path #{watermark_path ? watermark_path : "DNE"}"
      dst = Tempfile.new([@basename, @format].compact.join("."))
      dst.binmode

      command = "convert"
      params = [fromfile]
      params += transformation_command
      params << tofile(dst)

=begin
      begin
        success = Paperclip.run(command, params.flatten.compact.collect{|e| "'#{e}'"}.join(" "))
      rescue Paperclip::Errors::CommandNotFoundError
        raise Paperclip::Errors::CommandNotFoundError, "There was an error resizing and cropping #{@basename}" if @whiny
      end
=end
      begin
        Paperclip.run(command, params.join(' '))
      rescue Cocaine::ExitStatusError => e
        raise Paperclip::Error, "There was an error processing the watermark for #{@basename}" if @whiny
      rescue Cocaine::CommandNotFoundError => e
        raise Paperclip::Errors::CommandNotFoundError.new("Could not run the `convert` command. Please install ImageMagick.")
      end

      if watermark_path && @style == :large
        puts "In watermark with path " + watermark_path
        command = "composite"
        params = %W[-gravity #{@position} #{watermark_path} #{tofile(dst)}]
        params << tofile(dst)

        begin
          Paperclip.run(command, params.join(' '))
        rescue Cocaine::ExitStatusError => e
          raise Paperclip::Error, "There was an error processing the watermark for #{@basename}" if @whiny
        rescue Cocaine::CommandNotFoundError => e
          raise Paperclip::Errors::CommandNotFoundError.new("Could not run the `convert` command. Please install ImageMagick.")
        end
      end
=begin
        begin
          success = Paperclip.run(command, params.flatten.compact.collect{|e| "'#{e}'"}.join(" "))
        rescue Paperclip::Errors::CommandNotFoundError
          raise Paperclip::Errors::CommandNotFoundError, "There was an error processing the watermark for #{@basename}" if @whiny
        end
      end
=end

      dst
    end

    def fromfile
      File.expand_path(@file.path)
    end

    def tofile(destination)
      [@format, File.expand_path(destination.path)].compact.join(':')
    end

    def transformation_command
      if @target_geometry.present?
        scale, crop = @current_geometry.transformation_to(@target_geometry, crop?)
        trans = %W[-resize #{scale}]
        trans += %W[-crop #{crop} +repage] if crop
        trans += [*convert_options] if convert_options?
        trans
      else
        scale, crop = @current_geometry.transformation_to(@current_geometry, crop?)
        trans = %W[-resize #{scale}]
        trans += %W[-crop #{crop} +repage] if crop
        trans += [*convert_options] if convert_options?
        trans
      end
    end
  end
end