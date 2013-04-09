xml.instruct! :xml, :version => "1.0" 
xml.result do
  if(error_data[:error].present?) 
     xml.errors do
	error_data[:error].each do |error_entry|
	   xml.error do 
	      xml.parameter  error_entry[0]
	      xml.message  error_entry[1]
	   end
	end
     end
  else
    xml.success true
  end
end