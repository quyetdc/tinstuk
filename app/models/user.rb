class User < ActiveRecord::Base
	TEMP_EMAIL_PREFIX = 'change@me'
  TEMP_EMAIL_REGEX = /\Achange@me/
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

	has_many :friendships, dependent: :destroy
	has_many :inverse_friendships, class_name: "Friendship", foreign_key: "friend_id", dependent: :destroy

	has_attached_file :avatar,
					  :storage => :s3,
					  :style => { :medium => "370x370", :thumb => "100x100" }

  validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/
  validates_format_of :email, :without => TEMP_EMAIL_REGEX, on: :update

  default_scope { order('id DESC') }

	#def self.sign_in_from_facebook(auth)
	#	find_by(provider: auth['provider'], uid: auth['uid'] ) || create_user_from_facebook(auth)
	#end

	#def self.create_user_from_facebook(auth)
	#	create(
  
	#	avatar: process_uri(auth['info']['image'] + "?width=9999"),
	#	email: auth['info']['email'],
	#	provider: auth['provider'],
	#	uid: auth['uid'],
	#	name: auth['info']['name'],
	#	gender: auth['extra']['raw_info']['gender'],
	#	date_of_birth: auth['extra']['raw_info']['birthday'],
	#	location: auth['info']['location'],
	#	bio: auth['extra']['raw_info']['bio']


	#	)
	#end

	def self.find_for_oauth(auth, signed_in_resource = nil)
    user = signed_in_resource ? signed_in_resource : User.where(uid: auth.uid, provider: auth.provider).first
    
    if user.nil?
      email = auth.info.email 
      user = User.where(:email => auth.info.email).first if email
      
      if user.nil?
        user = User.new(
          name: auth.extra.raw_info.name,
          uid: auth.uid, 
          provider: auth.provider,
          email: email ? email : "#{TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com",
          password: Devise.friendly_token[0,20]
        )
        user.save!
      end
    end
    user
  end

  def email_verified?
    self.email && self.email !~ TEMP_EMAIL_REGEX
  end

	# Friendship Methods
	def request_match(user2)
		self.friendships.create(friend: user2)
	end

	def accept_match(user2)
		self.friendships.where(friend: user2).first.update_attribute(:state, "ACTIVE")
	end

	def remove_match(user2)
		
		inverse_friendship = inverse_friendships.where(user_id: user2).first

		if inverse_friendship
			self.inverse_friendships.where(user_id: user2).first.destroy
		else
			self.friendships.where(friend_id: user2).first.destroy
		end

	end

	# Friendship Methods


	# Filter Methods
	def self.gender(user)
		case user.interest
			when "Male"
			where('gender = ?', 'male')
			when "Female" 
			where('gender = ?', 'female')
			else
			all
		end
	end

	def self.not_me(user)
		where.not(id: user.id)
	end

	def matches(current_user)
		friendships.where(state: "pending").map(&:friend) + current_user.friendships.where(state: "ACTIVE").map(&:friend) + current_user.inverse_friendships.where(state: "ACTIVE").map(&:user) 
	end
	# Filter Methods

	

	private

	def self.process_uri(uri)
		avatar_url = URI.parse(uri)
		avatar_url.scheme = 'https'
		avatar_url.to_s
	end
	
end