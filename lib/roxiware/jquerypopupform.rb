module Roxiware
  module JQueryPopupForm
    def report_error(object)
      error_out = []
      object.errors.each do |attribute, error|
        error_out << [attribute.to_s(), error.to_s()]
      end
      return {:error=>error_out}
    end
  end
end
