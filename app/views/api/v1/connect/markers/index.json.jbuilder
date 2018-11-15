json.markers @markers do |marker|

  json.extract! marker, :id, :marker_type, :name, :description, :phone,
                        :categories, :latitude, :longitude, :address, :email, :data

  json.updated_at marker.updated_at.in_time_zone('Central Time (US & Canada)').rfc3339
end

json.meta do
  json.result_count @markers.length
  json.filters @filters
end
