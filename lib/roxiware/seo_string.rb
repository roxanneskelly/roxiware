class String
   def to_seo
      self.downcase.gsub(/[\.]/, '').gsub(/[^a-z0-9]+/i, '-').chomp("-")
   end
end
