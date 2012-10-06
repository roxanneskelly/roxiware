class Roxiware::Event < ActiveRecord::Base
   include Roxiware::BaseModel
   self.table_name="events"

   validates_presence_of :duration_units, :inclusion => {:in => %w(none minutes hours days)}
   validates_format_of :start_date, :with=>/\d{1,2}\/\d{1,2}\/\d{4}/
   validates_format_of :start_time, :with=>/\d{1,2}\:\d{2} (AM|PM)/
   
   edit_attr_accessible  :start_date, :start_time, :duration, :duration_units, :city, :state, :address, :location, :location_url, :description, :as=>[:super, :admin, :user, nil]

   ajax_attr_accessible  :start_date, :start_time, :duration, :duration_units, :city, :state, :address, :location, :location_url, :description


   attr_accessor :start_time
   attr_accessor :start_date

   before_validation do |event|
     if !(self.location_url.nil? || self.location_url.empty?)
       parsed_uri = URI::parse(self.location_url)
       parsed_uri.scheme = 'http' if parsed_uri.scheme.nil?
       if parsed_uri.host.nil?
         split_path = parsed_uri.path.split
         parsed_uri.host = split_path[0]
         parsed_uri.path = "/"+split_path[1..-1].join("/")
       end
       self.location_url = parsed_uri.to_s
     end
   end

   after_validation do |event|
     self.start = DateTime.strptime(event.start_date + " " + event.start_time, "%m/%d/%Y %l:%M %p")
   end

   after_initialize do |event|
     self.duration_units ||= "none"
     @start_date ||= DateTime.now.utc.strftime("%m/%d/%Y")
     @start_time ||= "12:00 AM"
   end

   after_find do |event|
     self.duration_units ||= "none"     
     self.start ||= DateTime.now.utc
     @start_date ||= self.start.strftime("%m/%d/%Y")
     @start_time ||= self.start.strftime("%l:%M %p").strip
   end
end
