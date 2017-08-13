class UserMerger

  def initialize(params)
    @old_user = params[:old_user]
    @new_user = params[:new_user]
    @skip_revision = params[:skip_revision] || false

    raise ArgumentError unless @old_user && @new_user
  end

  def merge_users!
    ActiveRecord::Base.transaction do

      # Merge posts.
      @old_user.posts.each do |post|
        post.set_owner(@new_user, @old_user, @skip_revision)
        PostAction.remove_act(@new_user, post, PostActionType.types[:like])
      end

      # Merge topics.
      @old_user.topics.each do |topic|
        topic.user_id = @new_user.id
        topic.update_statistics
        topic.save!
      end

      # Merge user actions.
      @old_user.user_actions.each do |user_action|
        user_action.user_id = @new_user.id
        user_action.save!
      end

      # Merge badges.
      @old_user.badges do |badge|
        if @new_user.badges.include? badge
          badge.destroy
        else
          badge.user_id = @new_user.id
          badge.save!
        end
      end

      # Merge groups.
      # Merge user emails.
      # Finally: disable old user.
    end
  end
end
