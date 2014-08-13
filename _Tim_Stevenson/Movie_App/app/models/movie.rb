class Movie < ActiveRecord::Base
  validates :title, :description, presence: true
  validates :description, length: { minimum: 10 }
  validates :year_released, numericality: {greater_than: 0}
  validates :year_released, length: {is: 4}

  def self.search_for(query)
    Movie.where('title LIKE :query OR description LIKE :query OR year_released LIKE :query', query: "%#{query}%")
  end

end
