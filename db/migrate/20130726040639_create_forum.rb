class CreateForum < ActiveRecord::Migration
  def change
    # Major grouping of forum boards
    create_table :forum_board_groups do |t|
      t.string :name
      t.integer :display_order
      t.timestamps
    end

    # Minor grouping of forum boards (represented as a blog category/term)
    create_table :forum_boards do |t|
      t.integer :board_group_id
      t.integer :display_order
      t.string  :name
      t.string  :description
      t.string  :permissions, :default=>"default"
      t.integer :topic_count, :default=>0
      t.integer :comment_count, :default=>0
      t.integer :pending_comment_count, :default=>0
      t.integer :last_post_id
      t.integer :last_post_date
      t.string  :seo_index
      t.timestamps
    end

    # Minor grouping of forum boards (represented as a blog category/term)
    create_table :forum_topics do |t|
      t.integer :board_id
      t.string  :title
      t.string  :permissions, :default=>"board"
      t.integer :comment_count, :default=>0
      t.integer :pending_comment_count, :default=>0
      t.integer :last_post_id
      t.integer :last_post_date
      t.string  :guid
      t.string  :topic_link
      t.timestamps
    end
    add_column :comments, :post_type, :string, :default=>"Roxiware::Blog::Post"

    Roxiware::Comment.where(:parent_id=>[0,nil]).each do |comment|
        comment.parent_type = "Roxiware::Blog::Post"
	comment.parent_id = 0
        comment.save!
    end
  end
end
