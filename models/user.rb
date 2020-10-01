class User < ActiveRecord::Base

  has_many :tweets
    
  def set_subscription_status!
    self.data['premium'] = subscribed?
    
    if self.data["stripe_subscription"]
      subscription = Stripe::Subscription.retrieve(self.data["stripe_subscription"])
    
      self.data["stripe_subscription_status"] = subscription.status
      self.data["stripe_subscription_end_date"] = Time.at(subscription.current_period_end)
    end
    
    self.save!
  end
  
  def secret_data
    data = "{}"
    if self.secret_key.present? && self.encrypted_data.present?
      data = decrypt_data(self.secret_key, self.encrypted_data)
    end
    JSON.parse(data)
  end
      
      
  def update_secret_key
    
    
  end
  
  def last_login
    DateTime.parse self.data['login_data'].reverse.first
  end
  
  def minutes_since_last_update
    last_tweet = self.tweets.order(created_at: :desc).first

    if last_tweet
      last_tweet_created_at = last_tweet.created_at
    else
      last_tweet_created_at = 30.minutes.ago
    end

    last_update_in_seconds = Time.current.getlocal("+00:00").to_i - last_tweet_created_at.getlocal("+00:00").to_i
    last_update_in_seconds / 60
  end
    
  
  def subscribed?
    # Needs research. There should be a simpler API call for this. 
    customer = self.data.to_h['stripe_customer']
    if customer
      Stripe::Customer.retrieve(customer).subscriptions.map{|s| 
        s.plan[:active] == true && s.plan[:product] == ENV['STRIPE_PRODUCT_KEY']
      }.first
    end
  end

  def cancel_subscription
    customer = self.data.to_h['stripe_customer']
    subscription = self.data.to_h['stripe_subscription']
    
    if customer
      Stripe::Subscription.delete(subscription)
    end
  end

end