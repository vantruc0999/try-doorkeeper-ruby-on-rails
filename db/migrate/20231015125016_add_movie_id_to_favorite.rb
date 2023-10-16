class AddMovieIdToFavorite < ActiveRecord::Migration[7.1]
  def change
    add_reference :favorites, :movie, null: false, foreign_key: true
  end
end
