require 'mini_magick'
require 'json'

class ImageImport

  @image_files = nil
  @path = nil

  def initialize
    puts "ImageImporter init"
    @exif_data = Hash.new
  end


  def import(path)
    @path = path
    @image_files = Dir["#{path}/*.JPG"].reject {|file| File.basename(file).match(/thumb.JPG/) != nil }
    puts "loaded #{@image_files.length} images"
  end


  def make_thumbnails
    if @image_files then
      count = 0
      @image_files.each do |file|
        image = MiniMagick::Image.open(file)
        image.resize("150x150")
        image.write(_image_thumb(file))
        puts "converting #{file}"
        count += 1
        #if count > 10 then break end
      end
    end
  end


  def load_exif_data
    if @image_files then
      count = 0
      @image_files.each do |file|
        #puts File.basename(file)
        meta_str = %x(exiftool -u -d "%Y-%m-%d %H:%M:%S" -json #{file})
        meta_arr = JSON.parse(meta_str)
        meta = meta_arr[0]

        #_correct_orientation file, meta['Orientation']

        @exif_data[File.basename(file)] = meta
        puts "loading exif data in json format from #{file}"
        count += 1
        #if count > 10 then break end
      end
    end
    @exif_data
  end


  def load_thumbnails(no_path = false)
    if no_path then
      path_saved = @path
      @path = ""
    end

    if @image_files then
      thumb_files = Array.new
      @image_files.each do |file|
        thumb_files.push _image_thumb(file)
      end
    end
    
    if no_path then
      @path = path_saved
    end
    
    thumb_files
  end

  def load_gmap_options(exif_data = false)
    if exif_data then
      @exif_data = exif_data
    end

    if @exif_data then
      gmap_options = Hash.new
      gmap_options['controls'] = false
      gmap_options['zoom'] = 5
      gmap_options['markers'] = Array.new

      @exif_data.each do |exif|
        latitude = exif[1]['GPSLatitude']
        longitude = exif[1]['GPSLongitude']

        if latitude then
          #puts "Converting: #{latitude} and #{longitude}"
          latlong   = _latlong(latitude + " " + longitude)
          latitude  = latlong[:latitude]
          longitude = latlong[:longitude]
          extra_css_classes = _extra_css_classes exif
          meta_data_ul = _metadata(exif[1]["DateTimeOriginal"], "Erstellt am:")
          meta_data_ul += _metadata(exif[1]["FocalLength"], "Brennweite:")
          meta_data_ul += _metadata(exif[1]["ExposureTime"], "Belichtungsdauer:")
          meta_data_ul += _metadata(exif[1]["ApertureValue"], "Blendenzahl:")
          html = '<img src="images' + _image_thumb(exif[0], no_path = true) + '" class="' + extra_css_classes + '" alt=""/><ul class="metadata">' + meta_data_ul + '</ul>'
          markers   = { latitude: latitude, longitude: longitude, html: html }
          gmap_options['markers'].push(markers)
        end
      end
      JSON.generate(gmap_options)
    end
  end

  #def _correct_orientation(file, orientation)
    # Horizontal (normal)
    # Rotate 90 CW
    # Rotate 270 CW
    #deg = orientation.match(/(.+) (\d+) CW/)
    #if deg != nil then
    #  image = MiniMagick::Image.open(file)
    #  image.rotate deg[0].to_s
    #  image.
    #end
  #end


  def process_images(&block)

  end


  protected

  def _extra_css_classes(exif)
    css_classes = ""

    #puts exif.class
    #puts exif.inspect

    # Orientation
    if exif[1]["Orientation"] then
      deg = exif[1]["Orientation"].match(/(.+) (\d+) CW/)
      if deg != nil then
        css_classes += "rotate-#{deg[2]}-cw "
      end
    end

    # Flash
    if exif[1]["Flash"] then
      puts "got flash!"
      css_classes += _friendly_string(exif[1]["Flash"]) + " "
    end

    css_classes
  end


  def _metadata(value, title)
    "<li>#{title} #{value}</li>"
  end

  def _image_thumb(file, no_path = false)
    file_name = File.basename(file, ".JPG") + ".thumb.JPG"

    if no_path then
      "/" + file_name
    else
      @path + "/" + file_name
    end
  end

  def _latlong(dms_pair)
    match = dms_pair.match(/(\d+) deg (\d+)' (\d+.+)" [NWES] (\d+) deg (\d+)' (\d+.+)" [NWES]/)
    latitude = match[1].to_f + match[2].to_f / 60 + match[3].to_f / 3600
    longitude = match[4].to_f + match[5].to_f / 60 + match[6].to_f / 3600
    {:latitude=>latitude, :longitude=>longitude}
  end

  def _friendly_string(string)
    string.gsub(/\s/, "-").gsub(/(,|\.)/, "").downcase
  end

end

#importer = ImageImport.new
#importer.import "public/images"
#importer.make_thumbnails
#e = importer.load_exif_data
#puts e

