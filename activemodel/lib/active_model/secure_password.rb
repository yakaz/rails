module ActiveModel
  module SecurePassword
    extend ActiveSupport::Concern

    module ClassMethods
      # Adds methods to set and authenticate against a BCrypt password.
      # This mechanism requires you to have a password_digest attribute.
      #
      # Validations for presence of password on create, confirmation of password (using
      # a "password_confirmation" attribute) are automatically added.
      # If you wish to turn off validations, pass 'validations: false' as an argument.
      # You can add more validations by hand if need be.
      #
      # You need to add bcrypt-ruby (~> 3.0.0) to Gemfile to use has_secure_password:
      #
      #   gem 'bcrypt-ruby', '~> 3.0.0'
      #
      # Example using Active Record (which automatically includes ActiveModel::SecurePassword):
      #
      #   # Schema: User(name:string, password_digest:string)
      #   class User < ActiveRecord::Base
      #     has_secure_password
      #   end
      #
      #   user = User.new(:name => "david", :password => "", :password_confirmation => "nomatch")
      #   user.save                                                      # => false, password required
      #   user.password = "mUc3m00RsqyRe"
      #   user.save                                                      # => false, confirmation doesn't match
      #   user.password_confirmation = "mUc3m00RsqyRe"
      #   user.save                                                      # => true
      #   user.authenticate("notright")                                  # => false
      #   user.authenticate("mUc3m00RsqyRe")                             # => user
      #   User.find_by_name("david").try(:authenticate, "notright")      # => false
      #   User.find_by_name("david").try(:authenticate, "mUc3m00RsqyRe") # => user
      def has_secure_password(options = {})
        # Load bcrypt-ruby only when has_secure_password is used.
        # This is to avoid ActiveModel (and by extension the entire framework) being dependent on a binary library.
        gem 'bcrypt-ruby', '~> 3.0.0'
        require 'bcrypt'

        attr_reader :password
        
        if options.fetch(:validations, true)
          validates_confirmation_of :password
          validates_presence_of     :password, :on => :create
          
          before_create { raise "Password digest missing on new record" if password_digest.blank? }
        end

        include InstanceMethodsOnActivation

        if respond_to?(:attributes_protected_by_default)
          def self.attributes_protected_by_default
            super + ['password_digest']
          end
        end
      end
    end

    module InstanceMethodsOnActivation
      # Returns self if the password is correct, otherwise false.
      def authenticate(unencrypted_password)
        BCrypt::Password.new(password_digest) == unencrypted_password && self
      end

      # Encrypts the password into the password_digest attribute, only if the
      # new password is not blank.
      def password=(unencrypted_password)
        unless unencrypted_password.blank?
          @password = unencrypted_password
          self.password_digest = BCrypt::Password.create(unencrypted_password)
        end
      end
    end
  end
end
