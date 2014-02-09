module Roxiware
  module JQueryPopupForm
    def report_error(object)
      error_out = object.errors.collect{|attribute, error| [attribute.to_s().split('.')[-1], error.to_s()]}
      return {:error=>error_out}
    end
  end
end
