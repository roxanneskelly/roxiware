include Roxiware::Helpers
include ActionView::Helpers::TagHelper
include ActionView::Helpers::UrlHelper
include ActionView::Context
module Roxiware::EventsHelper
    def self.event_header(event, options={})
        header_content = options
        date_format = options[:date_format] || "%Y"
        header_format = options[:header_format] || "%{title} <div class='event_full_time'>%{start_time} %{date_range}</div> <div class='event_full_location'>%{location} %{city},&nbsp;%{state}</div>"
        header_content[:title] = content_tag(:div, event.title, :class=>"event_title")
        show_date = event.start.strftime(date_format)
        header_content[:end_time] = end_time = event.end_time
        if ((event.start.day != end_time.day) || (event.start.month != end_time.month) || (event.start.year != end_time.year))
            show_date += " - " + end_time.strftime(date_format)
        end
        header_content[:date_range] = content_tag(:div, show_date.html_safe, :class=>"event_date_range")
        header_content[:start_time] = ((event.duration_units != "days") || (event.start_time != "12:00 AM")) ? content_tag(:div, event.start.strftime("%l:%M %p"), :class=>"event_start_time") : ""
        header_content[:location] = event.location.present? ? content_tag(:div, event.location_url.present? ? link_to(event.location, event.location_url, :target=>"_blank") : event.location, :class=>"event_location") : ""
        header_content[:city] = event.city.present? ? content_tag(:div, event.city, :class=>"event_city") : ""
        header_content[:state] = event.state.present? ? content_tag(:div, event.state, :class=>"event_state") : ""
        content_tag(:div, (header_format % header_content).html_safe, :class=>"event_header")
    end
end

