require 'rubygems'
require 'yaml'
require 'mongo_mapper'

@config = YAML.load_file("config/database.yaml")

@environment = @config["environment"]

@db_host = @config[@environment]["host"]
@db_port = @config[@environment]["port"]
@db_name = @config[@environment]["database"]
@db_log = @config[@environment]["logfile"]

MongoMapper.connection = Mongo::Connection.new(@db_host, @db_port)
MongoMapper.database = @db_name
MongoMapper.connection.connect

