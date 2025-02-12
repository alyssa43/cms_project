require "sinatra"
require "sinatra/reloader"
require "tilt/erubi"

DATA_PATH = File.join(__dir__, "data") # returns String path to `data` directory => "/Users/alyssaeaster/cms_project/data"

def get_file_path(file_name)
  File.join(__dir__, "data", file_name)
end

get "/" do
  @files = Dir.glob(File.join(DATA_PATH, "*")).map do |path|
    File.basename(path)
  end # returns an Array of string File paths => ["about.txt", "changes.txt", "history.txt"]

  erb :index
end

get "/:file" do
  file_path = get_file_path(params[:file])
  headers["Content-Type"]= "text/plain"
  File.read(file_path)
end