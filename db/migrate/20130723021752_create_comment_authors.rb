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

    add_column :comments, :comment_author_id, :integer
    add_column :comments, :parent_type, :string

    # when applying the migration, create comment_author entries for each 
    # author listed in the comments
    rename_column :comments, :comment_author, :comment_author_name
    Roxiware::Comment.all.each do |comment|
       if comment.person_id.present? && (comment.person_id >= 0)
           author = comment.build_comment_author({:name=>comment.comment_author_name, :url=>comment.comment_author_url,:email=>comment.comment_author_email, :authtype=>"roxiware",:uid=>"",:person_id=>comment.person_id}, :as=>"")
       else
           author = comment.build_comment_author({:name=>comment.comment_author_name, :url=>comment.comment_author_url,:email=>comment.comment_author_email, :authtype=>"generic",:uid=>comment.comment_author_email,:person_id=>0}, :as=>"")
       end
       comment.save(:validate=>false)
    end
    remove_column :comments, :comment_author_name
    remove_column :comments, :comment_author_url
    remove_column :comments, :comment_author_email
    remove_column :comments, :person_id
  end
end
