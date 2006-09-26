# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes     = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils        = true

# Enable the breakpoint server that script/breakpointer connects to
config.breakpoint_server = true

config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = false

config.action_mailer.raise_delivery_errors = true
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.server_settings = { 
   :address => "localhost", 
   :port => 25, 
   :domain => "ehatchersolutions.com"
} 

SOLR_URL                                           = "http://localhost:8983"

config.log_level = :info
#ActiveRecord::Base.verification_timeout=100