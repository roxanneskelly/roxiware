class CreateCommentAuthors < ActiveRecord::Migration
  def change
    create_table :comment_authors do |t|
      t.string :url
      t.string :email
      t.string :name
      t.string :authtype
      t.string :uid
      t.integer :person_id
      t.timestamps
    end

    rename_table :blog_comments, :comments

    # when applying the migration, create comment_author entries for each 
    # author listed in the comments
    Roxiware::Comment.all.each do |comment|
       if comment.person_id == 0
           Roxiware::CommentAuthor.create(:name=>comment.comment_author, :url=>comment.comment_author_url,:email=>comment.comment_author_email, :authtype=>"roxiware",:uid=>"",:person_id=>comment.person_id,:comment_object_id=>comment.id,:comment_object_type=>"Roxiware::Comment")
       else
           Roxiware::CommentAuthor.create(:name=>comment.comment_author, :url=>comment.comment_author_url,:email=>comment.comment_author_email, :authtype=>"generic",:uid=>"",:person_id=>0,:comment_object_id=>comment.id,:comment_object_type=>"Roxiware::Comment")
       end
    end
    remove_column :comments, :comment_author
    remove_column :comments, :comment_author_url
    remove_column :comments, :comment_author_email
    remove_column :comments, :person_id
    add_column :comments, :comment_author_id, :integer
    add_column :comments, :parent_type, :string
    Roxiware::Comment.where(:parent_id=>0).each do |comment|
        comment.parent_id = comment.post_id
        comment.parent_type = "Roxiware::Blog::Post"
        comment.save!
    end
  end
end
