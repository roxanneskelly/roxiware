class String
   def to_seo
      self.downcase.strip.gsub(/[\.]/, '').gsub(/[^a-z0-9]+/i, '-').chomp("-")
   end
end
