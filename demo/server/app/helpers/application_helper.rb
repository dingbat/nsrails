module ApplicationHelper
  def link_to_wiki(content)
    link_to content, "https://github.com/dingbat/nsrails/wiki"
  end

  def link_to_source(content)
    link_to content, "https://github.com/dingbat/nsrails"
  end

  def link_to_screencast(content)
    link_to content, "http://vimeo.com/dq/nsrails"
  end
  
  def fork_me_ribbon(link)
    image = image_tag "http://s3.amazonaws.com/github/ribbons/forkme_right_red_aa0000.png", :id=>"ribbon", :alt=>"Fork me on GitHub"
    link_to image, link
  end
end
