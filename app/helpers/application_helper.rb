# The methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Accepts a container (hash, array, enumerable, your type) and returns a string of option tags. Given a container 
  # where the elements respond to first and last (such as a two-element array), the "lasts" serve as option values and
  # the "firsts" as option text. Hashes are turned into this form automatically, so the keys become "firsts" and values
  # become lasts. If +selected+ is specified, the matching "last" or element will get the selected option-tag.
  #
  # Examples (call, result):
  #   html_options([["Dollar", "$"], ["Kroner", "DKK"]])
  #     <option value="$">Dollar</option>\n<option value="DKK">Kroner</option>
  #
  #   html_options([ "VISA", "Mastercard" ], "Mastercard")
  #     <option>VISA</option>\n<option selected>Mastercard</option>
  #
  #   html_options({ "Basic" => "$20", "Plus" => "$40" }, "$40")
  #     <option value="$20">Basic</option>\n<option value="$40" selected>Plus</option>
  def html_options(container, selected = nil)
    container = container.to_a if Hash === container
  
    html_options = container.inject([]) do |options, element| 
      if element.respond_to?(:first) && element.respond_to?(:last)
        if element.last != selected
          options << "<option value=\"#{element.last}\">#{element.first}</option>"
        else
          options << "<option value=\"#{element.last}\" selected>#{element.first}</option>"
        end
      else
        options << ((element != selected) ? "<option>#{element}</option>" : "<option selected>#{element}</option>")
      end
    end
    
    html_options.join("\n")
  end

  # Creates a hyperlink to a Wiki page, without checking if the page exists or not
  def link_to_existing_page(page, text = nil, html_options = {})
    link_to(
        text || page.plain_name, 
        {:web => @web.address, :action => 'show', :id => page.name, :only_path => true},
        html_options)
  end
  
  # Creates a hyperlink to a Wiki page, or to a "new page" form if the page doesn't exist yet
  def link_to_page(page_name, web = @web, text = nil, options = {})
    raise 'Web not defined' if web.nil?
    UrlGenerator.new(@controller).make_link(page_name, web, text, 
        options.merge(:base_url => "#{base_url}/#{web.address}"))
  end

  def author_link(page, options = {})
    UrlGenerator.new(@controller).make_link(page.author.name, page.web, nil, options)
  end

  def base_url
    home_page_url = url_for :controller => 'admin', :action => 'create_system', :only_path => true
    home_page_url.sub(%r-/create_system/?$-, '')
  end

  # Creates a menu of categories
  def categories_menu
    if @categories.empty?
      ''
    else 
      "<div id=\"categories\">\n" +
      '<strong>Categories</strong>:' +
      '[' + link_to_unless_current('Any', :web => @web.address, :action => @action_name) + "]\n" +
      @categories.map { |c| 
        link_to_unless_current(c, :web => @web.address, :action => @action_name, :category => c)
      }.join(', ') + "\n" +
      '</div>'
    end
  end

  # Performs HTML escaping on text, but keeps linefeeds intact (by replacing them with <br/>)
  def escape_preserving_linefeeds(text)
    h(text).gsub(/\n/, '<br/>')
  end

  def format_date(date)
    # Must use DateTime because Time doesn't support %e on at least some platforms
    DateTime.new(date.year, date.mon, date.day, date.hour, date.min, 
        date.sec).strftime("%B %e, %Y %H:%M:%S")
  end

  def rendered_content(page)
    PageRenderer.new(page.revisions.last).display_content
  end

end
