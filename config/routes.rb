Roxiware::Engine.routes.draw do
  Roxiware::RoutingHelpers.applications.each do |application|
      send("roxiware_#{application}")
  end
end
