require 'sinatra/base'
require 'sinatra/mongomapper'
require 'haml'
require 'sass'

## MongoMapper Config


## Models
class ExifData
  include MongoMapper::Document

  key :image, String
  key :exif, Hash
end


class MyApp < Sinatra::Base

  set :mongomapper, 'mongomapper://localhost:27017/exif_data'
  set :public, File.dirname(__FILE__) + '/public'

  before do
    if request.env['SERVER_NAME'] == '192.168.123.100' then 
      @google_api_key = 'ABQIAAAAElw0yrWRXCtU2och7ZDtTRTynE7QvoIqnh7GP-66-bcOP0hdihTGr3ZQ5_U4USC1TO2vd5vanhgfMA'
    elsif request.env['SERVER_NAME'] == 'localhost' then
      @google_api_key = 'AABQIAAAAElw0yrWRXCtU2och7ZDtTRT2yXp_ZAY8_ufC3CFXhHIE1NvwkxTYGR_N-SbnjR200Xr3pZFrUbbcY'
    else
      @google_api_key = "what?"
    end
  end

  get '/style.css' do
    sass :style
  end

  get '/' do
    haml :index
  end

  get '/make_thumbnails' do
    require './imageimport.rb'
    importer = ImageImport.new
    importer.import "public/images"
    importer.make_thumbnails

    "Successfully created thumbnails"
  end

  get '/load_exif_data' do
    require './imageimport.rb'
    importer = ImageImport.new
    importer.import "public/images"
    @exif_data = importer.load_exif_data
    ExifData.delete_all
    @exif_data.each do |image, exif|
      ExifData.create(:image => image, :exif => exif)
    end
    "Successfully loaded exif data"
  end

  get '/gallery' do
    require './imageimport.rb'
    importer = ImageImport.new
    importer.import "public/images"
    #exif_data = importer.load_exif_data
    exif_data = ExifData.all
    @exif_data = Hash.new
    exif_data.each do |exif_obj|
      @exif_data[exif_obj.image] = exif_obj.exif
    end

    @gmap_options = importer.load_gmap_options @exif_data
    #@thumb_images = importer.load_thumbnails(no_path = true)

    @thumb_images = @exif_data

    haml :gallery
  end

  #run!
end
