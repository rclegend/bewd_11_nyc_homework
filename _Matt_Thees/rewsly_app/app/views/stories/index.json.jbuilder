json.array!(@stories) do |story|
  json.extract! story, :id, :title, :link, :upvotes, :category
  json.url story_url(story, format: :json)
end
