require_relative 'config/environment'
require 'date'

#welcomes the user
def welcome_user
    space(50)
    puts "Welcome to Ticketmaster Lite!"
    double_line
    space(1)
end 

#ask user if they have an account then login or create one
def login_or_create_user
    puts "Do you have an account with us? Type (y/n)"
    line
    input = get_input
    if input == 'y'
        login_user
    elsif input == 'n'
        create_user
    else 
        invalid_input
        login_or_create_user
    end 
end 

#if user exsit this method logs user in
def login_user
    space(1)
    puts "Please enter your username."
    line
    space(1)
    username = get_input
    if User.find_by(username: username)
        logged_in_user = User.find_by(username: username)
        space(1)
        puts "Welcome back #{username}!"
        line
        space(1)
        $logged_in = logged_in_user
    else 
        puts "Sorry, username does not exist."
        line
        login_or_create_user
    end 
end 

#If user doesn't exsist create one else log in user
def create_user
    line
    puts "Let's get you into the club! Create a unique username below:"
    line
    username = gets.chomp
    if User.find_by(username: username)
        puts "Sorry, that username is taken! Be more .uniq, playa."
        line
        create_user
        space(1)
    else
    logged_in_user = User.create(username: username)
    space(1)
    puts "Nice name, #{username}!"
    $logged_in = logged_in_user
    end
end 

# If user wants to delete account, they will go through this option.
def delete_account
    
    puts 'Are you sure you would like to delete your account?'
    puts "(y/n?)"
    answer = get_input
    if answer == 'y'
        puts "Please enter your username: "
        input = get_input
        if User.find_by(username: input) == $logged_in
            User.find_by(username: input).destroy
            puts "Sorry to see you go, come back soon!"
            exit
        else
            space(3)
            puts "You jerk. You can only delete your account."
            space(1)
            delete_account
        end 
    else
        run
    end  
end

#gives user a list of options to choose from
def present_menu_options
    space(1)
    puts "Choose an option from the list below."
    space(1)
    puts '1. Search for events by city'
    puts '2. Search for events by artist or sports team'
    puts '3. See what I have coming up'
    puts '4. Delete my account'
    puts '5. exit'
    space(1)
    pick_option
end 

#depending on the user input from main menu starts option flow
def pick_option
    input = get_input
    if input == '1'
        events_array = search_by_city
        space(50)
        display_events_by_city(events_array)
        save_event_or_main_menu(events_array)
     elsif input == '2'
        attractions_array = search_by_keyword
        space(50)
        display_by_keyword(attractions_array)
        save_event_or_main_menu(attractions_array)
     elsif input == '3'
        display_user_events
     elsif input == '4'
        space(50)
        delete_account
     elsif input == '5'
        space(1)
        puts "Thanks for checking us out. See ya later!"
        exit
     else
        space(1)
        invalid_input
        pick_option
    end
end 

#takes user input and searches; returns an array
def search_by_city
    space(1)
    puts "Where would you like to look?"
    space(1)
    city = get_input
    url = "https://app.ticketmaster.com/discovery/v2/events?apikey=pyLDDCYURYJ8LZfAUnOayESRsPBTWnKM&locale=*&city=#{city}&sort=date,asc"
    response = RestClient.get(url)
    if JSON.parse(response).key?("_embedded")
        events = JSON.parse(response)["_embedded"]["events"]
        events[0...20]
    else
        puts "This search received no results. Try again."
        search_by_city
    end
end

#takes user input and searches; returns an array
def search_by_keyword
    space(1)
    puts "What do you want to search for?"
    space(1)
    keyword = get_input
    url = "https://app.ticketmaster.com/discovery/v2/events?apikey=pyLDDCYURYJ8LZfAUnOayESRsPBTWnKM&keyword=#{keyword}&locale=en&sort=date,asc"
    response = RestClient.get(url)
    attractions = JSON.parse(response)["_embedded"]["events"]
    attractions[0...20]
end

#takes the return of search_by method option 1 and displays them in a readable manner
def display_events_by_city(events_array)
    if events_array.length == 0
        puts "Sorry there are no results for your search!"
        present_menu_options
    end
    events_array.each_with_index do |event, index|
        puts (index+1).to_s + '.' 
        line
        name = event["name"]  || 'nil'
        date = event["dates"]["start"]["localDate"] || 'nil'
        url = event["url"] || 'nil'
        print " Event name: #{name} \n  Event date: #{date} \n  Event url: #{url} \n "
        if Event.find_by(event_type: url) == nil
            $event = create_event(name, date , url)
        end 
        line
        space(2)
    end
    click?
end 

# takes the return of search_by method option 2 and displays them in a readable manner
def display_by_keyword(attractions_array)
    attractions_array.each_with_index do |attraction, index|
        puts (index+1).to_s + '.'
        line
        name = attraction["name"] || 'nil'
        date = attraction["dates"]["start"]["localDate"] || 'nil'
        url = attraction["url"] || 'nil'
        print " Event name: #{name} \n  Event date: #{date} \n  Event url: #{url} \n "
        if Event.find_by(event_type: url) == nil
            $event = create_event(name, date , url)
        end
        line
        space(2)
    end
    click?
end

def save_event_or_main_menu(events_array)
    space(1)
    puts "Would you like to save any of these events? Type 'y' to save an event or 'n' to go back to the main menu."
    space(1)
    response = get_input
    if response == 'y'
        space(1)
        puts 'To save an event please type the correlating number that corresponds with that event.'
        events_number = get_input.to_i
        url = events_array[events_number-1]["url"]
        event = Event.find_by(event_type: url)
        save_event(event.id)
        space(1)
        puts "You saved #{event.name}!" #dont know why it's breaking here..
        space(1)
        present_menu_options
    elsif response == 'n'
        present_menu_options
    else 
        invalid_input
        save_event_or_main_menu(events_array)
    end
end

def display_user_events
    space(40)
    puts "Here's a list of your events!"
    line
    space(1)
    user_events = UserEvent.select{|event| event.user_id == $logged_in.id}
    event_objects = user_events.map{|ueo| Event.find(ueo.event_id)}
    i = 0
    event_objects.each_with_index do |eo, index| 
        puts (index+1).to_s + '.'
        print "Event name: #{eo.name} \nEvent date: #{eo.date} \nEvent url: #{eo.event_type} \n "
        line
    end 
    space(2)
    click?
    space(2)
    puts "Nice events!"
    space(3)
    puts "If you would like to remove an event from you calendar"
    puts "please enter 'edit'. Otherwise, just hit Enter to return"
    puts "to the main menu."
    space(2)
    end_of_display_user_events(event_objects)
end

def end_of_display_user_events(event_objects)
    input = get_input
    if input == 'edit'
        delete_user_event(event_objects)
    elsif input == ''
        present_menu_options
    else 
        invalid_input
        end_of_display_user_events(event_objects)
    end
end

def delete_user_event(event_objects)
    puts "Please type the number of the event you would like removed: "
    input = get_input.to_i
    delete = event_objects[input-1]
    num = delete.id
    if UserEvent.find_by(event_id: num)
        UserEvent.find_by(event_id: num).destroy
        display_user_events
    else
        invalid_input
    end 
end 


 

#====================================================================================================================
#====================================================================================================================
#THE BIG CHULUPA 
def run
welcome_user
login_or_create_user
present_menu_options
end
#====================================================================================================================
#====================================================================================================================

#helper methods
def get_input
    if $logged_in
        print "#{$logged_in.username} > "
        gets.chomp 
    else
        print "User > "
        gets.chomp
    end
end

def click?
    double_line
    puts "To see more about an event hold command and left click the URL!"
    double_line
end

#create methods
def create_event(name = nil, date = nil, url = nil)
    Event.create(name: name, date: date, event_type: url)
end 

def save_event(event_id)
    UserEvent.create(user_id: $logged_in.id, event_id: event_id) 
end

#message helper methods
def invalid_input
    space(1)
    puts "Please enter a valid response"
end

#visual helper methods
def space(num)
    num.times do
        puts "\n"
    end 
end 

def line
    puts "-"*65
end 

def double_line
    puts "="*65
end

### NOTES
# $key = pyLDDCYURYJ8LZfAUnOayESRsPBTWnKM
# response = RestClient.get(url)
# EVENTBRITE_API_BASE_URL = response_string = RestClient.get('https://app.ticketmaster.com/discovery/v2/events.json?apikey='+ $key + '&city=' + city + '&size=25&localStartDateTime=' + date + 'T00:00:00,' + date + 'T23:59:59')
# response_hash = JSON.parse(response)

# title = events_array[0]["name"]
# event_url = events_array[0]["url"]
# event_date = events_array[0]["dates"]["start"]["localDate"]


# def get_events_for_artist_and_city(artist, city)
#     response_string = RestClient.get('https://app.ticketmaster.com/discovery/v2/events.json?apikey='+ $key + '&city=' + city + '&size=25&keyword=' + artist )
#     response_hash = JSON.parse(response_string)
#     convert_json_data_to_ruby_objects(response_hash)
#     display_output_with_date
#     event = retrieve_user_selection
#     event_info(event)
# end

