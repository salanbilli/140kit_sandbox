class Pretty
  
  def self.language_map
    {"en" => "English", "ja" => "Japanese", "it" => "Italian", "de" => "German", "fr" => "French", "kr" => "Korean", "es" => "Spanish"}
  end

  def self.pretty_up_labels(graph, graph_points)
    case graph.title
    when "tweets_location"
      graph_points = Pretty.location(graph_points)
    when "tweets_language"
      graph_points.collect{|graph_point| graph_point[:label] = Pretty.language(graph_point[:label])}
    when "tweets_created_at"
      graph_points = Pretty.time_generalize(graph_points)
    when "tweets_source"
      graph_points.collect{|graph_point| graph_point[:label] = Pretty.source(graph_point[:label])}
    when "users_lang"
      graph_points.collect{|graph_point| graph_point[:label] = Pretty.language(graph_point[:label])}
    when "users_created_at"
      graph_points = Pretty.time_generalize(graph_points)
    end
    return graph_points
  end
  
  def self.location(graph_points)
    graph_points.select{|graph_point| graph_point[:label] = "Not Reported" if graph_point[:label].nil?}
    iphone_graph_points = graph_points.select{|graph_point| graph_point[:label].include?("\303\234T:") || graph_point[:label].include?("UT:") || graph_point[:label].include?("iPhone:")}
    iphone_graph_point = iphone_graph_points.empty?  ? nil : {:label => "iPhone Location", :curation_id => graph_points.first[:curation_id], :graph_id => graph_points.first[:graph_id], :value => iphone_graph_points.length}
    pre_graph_points = graph_points.select{|graph_point| graph_point[:label].include?("Pre:")}
    pre_graph_point = pre_graph_points.empty?  ? nil : {:label => "Palm Pre Location", :curation_id => graph_points.first[:curation_id], :graph_id => graph_points.first[:graph_id], :value => pre_graph_points.length}
    new_graph_points = ((graph_points-[iphone_graph_points,pre_graph_points].flatten)+[iphone_graph_point,pre_graph_point].flatten).compact
    return new_graph_points
  end

  def self.language(language)
    return self.language_map[language]
  end
    
  def self.source(source)
    if source.include?("</a>")
      source = source.scan(/>(.*)</)[0][0]
    end
    return source.gsub("\"", "\\\"")
  end

  def self.time_generalize(graph_points)
    debugger
    sorted_times = graph_points.collect{|g| Time.parse(g[:label].to_s).to_i}.sort
    length = sorted_times.last-sorted_times.first
    if length < 60
      return Pretty.time_rounder(graph_points, "%b %d, %Y, %H:%M:%S")
    elsif length < 3600
      return Pretty.time_rounder(graph_points, "%b %d, %Y, %H:%M")
    elsif length < 86400
      return Pretty.time_rounder(graph_points, "%b %d, %Y, %H")
    elsif length < 11536000 #31536000
      return Pretty.time_rounder(graph_points, "%b %d, %Y")
    else 
      return Pretty.time_rounder(graph_points, "%b %Y")
    end
  end
  
  def self.time_rounder(graph_points, time_format)
    graph_point_counts = {}
    graph_points.each do |graph_point|
      time = graph_point[:label]
      if graph_point_counts[time.strftime(time_format)].nil?
        graph_point_counts[time.strftime(time_format)] = {:label => time.strftime(time_format), :value => graph_point[:value].to_i, :curation_id => graph_point[:curation_id], :graph_id => graph_point[:graph_id]}
      else
        graph_point_counts[time.strftime(time_format)][:value] += graph_point[:value].to_i
      end
    end
    final_graphs = []
    graph_point_counts.keys.sort.each do |graph_key|
      final_graphs << graph_point_counts[graph_key]
    end
    return final_graphs
  end
end
