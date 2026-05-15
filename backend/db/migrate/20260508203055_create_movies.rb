class CreateMovies < ActiveRecord::Migration[8.1]
  def change
    create_table :movies do |t|
      t.integer :tmdb_id
      t.string :title
      t.string :original_title
      t.text :overview
      t.date :release_date
      t.float :popularity
      t.float :vote_average
      t.string :original_language
      t.string :poster_path
      t.string :backdrop_path
      t.text :genres

      t.timestamps
    end
  end
end
