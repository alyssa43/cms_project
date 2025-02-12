require "sinatra"
require "sinatra/reloader"
require "tilt/erubi"

DATA_PATH = File.join(__dir__, "data") # returns String path to `data` directory => "/Users/alyssaeaster/cms_project/data"

get "/" do
  @files = Dir.glob(File.join(DATA_PATH, "*")) # returns an Array of string File paths => ["/Users/alyssaeaster/cms_project/data/about.txt", "/Users/alyssaeaster/cms_project/data/changes.txt", "/Users/alyssaeaster/cms_project/data/history.txt"]

  erb :index
end