require "sinatra"
require "sinatra/reloader"
require "tilt/erubi"
require "redcarpet"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

DATA_PATH = File.join(__dir__, "data") # returns String path to `data` directory => "/Users/alyssaeaster/cms_project/data"

def get_file_path(file_name)
  File.join(__dir__, "data", file_name)
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(file_path)
  content = File.read(file_path)
  case File.extname(file_path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    render_markdown(content)
  end
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

get "/" do
  @files = Dir.glob(File.join(DATA_PATH, "*")).map do |path|
    File.basename(path)
  end # returns an Array of string File paths => ["about.md", "changes.txt", "history.txt"]

  erb :index
end

get "/:filename" do
  file_path = get_file_path(params[:filename])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:error] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  file_path = get_file_path(params[:filename])

  if File.exist?(file_path)
    @file_name = params[:filename]
    @content = File.read(file_path)
    erb :edit
  else
    session[:error] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

post "/:filename/save" do
  file_path = get_file_path(params[:filename])

  File.write(file_path, params[:content])
  session[:success] = "#{params[:filename]} has been updated"
  redirect "/"
end

# about_text = <<~TEXT
# # Ruby is....

# A dynamic, open source programming language with a focus on simplicity and productivity. It has an elegant syntax that is natural to read and easy to write.
# TEXT
