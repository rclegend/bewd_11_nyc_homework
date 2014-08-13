class Url < ActiveRecord::Base
	validates :link, presence: true,
		  length: { minimum: 5 }	

	def self.search_for(query)
    Url.where('code LIKE :query', query: "#{:code}")
	end
end
