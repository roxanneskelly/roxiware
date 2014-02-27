class Roxiware::DeviseMailer < Devise::Mailer   
    helper :application # gives access to all helpers defined within `application_helper`.
    include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

    def controller
       nil
    end
    def reset_password_instructions(record, token, opts={})
        opts[:subject] = "A password reset request was received for your Scribaroo.com account"

        super
    end
end
