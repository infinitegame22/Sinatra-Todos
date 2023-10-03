require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "sinatra/content_for"

configure do
  use Rack::Session::Cookie, :key=>"rack.session", :path=>"/" 
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
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
  p @lists # [{:name=>"Home", :todos=>[{:name=>"Kitchen", :completed=>false}, {:name=>"Bathroom", :completed=>false}]}]
  p session # {"session_id"=>"a7d148a799bd7283902400874d388e661bf77bf2b1646a69f22469a8e930bc62", "lists"=>[{:name=>"Home", :todos=>[{:name=>"Kitchen", :completed=>false}, {:name=>"Bathroom", :completed=>false}]}]}
  p params # {}
  erb :lists, layout: :layout
end

# render the new list form
get "/lists/new" do
  erb :new_list
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "The list name must be between 1 and 100 characters."
  elsif session[:lists].any? {|list| list[:name] == name }
     "The list name must be unique."
  end
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo must be between 1 and 100 characters."
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

get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list_index
end

# Edit an existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :edit_list
end

# Update an existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = session[:lists][id]
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{id}"
  end
end

# Delete a todo list
post "/lists/:id/destroy" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# Add a new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip
  
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list_index
  else
    @list[:todos] << {name: text, completed: false}
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  
  todo_id = params[:id].to_i
  @list[:todos].delete_at todo_id
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@list_id}"
end