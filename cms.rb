require "sinatra"
require "sinatra/reloader"
require "tilt/erubi"
require "redcarpet"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

def data_path 
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__) # => "/Users/alyssaeaster/cms_project/test/data"
  else
    File.join(__dir__, "data") # => "/Users/alyssaeaster/cms_project/data"
  end
end

def get_file_path(file_name)
  File.join(data_path, file_name)
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
    erb render_markdown(content)
  end
end

def redirect_signed_out_user
  unless signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def signed_in?
    session[:username]
  end
end

# View list of files
get "/" do
  # redirect "/users/signin" unless session[:username] # prevents a user from seeing documents after being signed out, but fails one of the LS tests so commenting it out for now

  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end # returns an Array of string File paths => ["about.md", "changes.txt", "history.txt"]

  erb :index, layout: :layout
end

# Display the signin form
get "/users/signin" do
  erb :signin, layout: :layout
end

# Process signin form
post "/users/signin" do
  username = params[:username]
  password = params[:password]

  if username == "admin" && password == "secret"
    session[:username] = "admin"
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials."
    status 422
    erb :signin, layout: :layout
  end
end

post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end

# Create a new file
get "/new" do
  redirect_signed_out_user

  erb :new, layout: :layout
end

get "/:filename" do
  file_path = get_file_path(params[:filename])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

# Edit an existing file
get "/:filename/edit" do
  redirect_signed_out_user

  file_path = get_file_path(params[:filename])

  if File.exist?(file_path)
    @file_name = params[:filename]
    @content = File.read(file_path)
    erb :edit, layout: :layout
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

# Create a new file
post "/create" do
  redirect_signed_out_user

  file_name = params[:filename].to_s

  if File.extname(file_name).empty?
    session[:message] = "A name and valid extension is required."
    status 422
    erb :new, layout: :layout
  else
    file_path = File.join(data_path, file_name)

    File.write(file_path, "")
    session[:message] = "#{file_name} has been created."

    redirect "/"
  end
end

# Save contents of edited file
post "/:filename" do
  redirect_signed_out_user

  file_path = get_file_path(params[:filename])

  if File.exist?(file_path)
    File.write(file_path, params[:content])
    session[:message] = "#{params[:filename]} has been updated."
  else
    session[:message] = "#{params[:filename]} does not exist."
  end
  redirect "/"
end

# Delete an existing file
post "/:filename/delete" do
  redirect_signed_out_user
  
  file_name = params[:filename]
  file_path = get_file_path(file_name)

  File.delete(file_path) if File.exist?(file_path)

  session[:message] = "#{file_name} has been deleted."
  redirect "/"
end
