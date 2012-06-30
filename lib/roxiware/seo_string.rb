class String
   def to_seo
      self.downcase.gsub(/[^a-z0-9]+/i, '-')
   end
end