require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# GET /lists   -> view all lists
# GET /lists/new -> new list form
# POST /lists  -> create new list
# GET /lists/1 -> view a single list
# GET /users
# GET /users/1 -> The URL's are mapped to a pattern we can identify

# View list of lists
get "/lists" do
  @lists = session[:lists]
  session.inspect
  erb :lists, layout: :layout
end

# render the new list form
get "/lists/new" do
  erb :new_list
end

get "/lists/:list_index" do 
  "Hello #{params["list_index"]}"
  # erb :list_index
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "The list name must be between 1 and 100 characters."
  elsif session[:lists].any? {|list| list[:name] == name }
     "The list name must be unique."
  end
 
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
    if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end

  
end

set :session_secret, SecureRandom.hex(32)