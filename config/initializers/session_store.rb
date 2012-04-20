# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_archimate_session',
  :secret      => 'b76155e6400e021fb8b37042d50a6d42936583a6584f48e59a1927116b34e7e479433469baed9f38e53c9ea57147ff3c23aca149509d1c127ce75a9a9c4549d6'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
