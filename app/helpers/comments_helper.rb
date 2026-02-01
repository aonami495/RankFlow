# frozen_string_literal: true

module CommentsHelper
  def edit_comment_path(commentable, comment)
    case commentable
    when Keyword
      edit_site_keyword_comment_path(commentable.site, commentable, comment)
    when Site
      edit_site_comment_path(commentable, comment)
    end
  end

  def destroy_comment_path(commentable, comment)
    case commentable
    when Keyword
      site_keyword_comment_path(commentable.site, commentable, comment)
    when Site
      site_comment_path(commentable, comment)
    end
  end

  def create_comment_path(commentable)
    case commentable
    when Keyword
      site_keyword_comments_path(commentable.site, commentable)
    when Site
      site_comments_path(commentable)
    end
  end

  def commentable_path
    case @commentable
    when Keyword
      site_keyword_path(@site, @commentable)
    when Site
      site_path(@commentable)
    else
      root_path
    end
  end
end
