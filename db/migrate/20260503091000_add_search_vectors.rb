class AddSearchVectors < ActiveRecord::Migration[8.1]
  def up
    add_column :forum_threads, :search_vector, :tsvector
    add_column :posts,         :search_vector, :tsvector

    add_index :forum_threads, :search_vector, using: :gin, name: "idx_threads_search"
    add_index :posts,         :search_vector, using: :gin, name: "idx_posts_search"

    execute <<~SQL
      UPDATE forum_threads
      SET search_vector = to_tsvector('english', coalesce(title, ''));

      UPDATE posts
      SET search_vector = to_tsvector('english', coalesce(body, ''));
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION forum_threads_search_vector_update() RETURNS trigger AS $$
      BEGIN
        NEW.search_vector := to_tsvector('english', coalesce(NEW.title, ''));
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER forum_threads_search_update
      BEFORE INSERT OR UPDATE ON forum_threads
      FOR EACH ROW EXECUTE FUNCTION forum_threads_search_vector_update();

      CREATE OR REPLACE FUNCTION posts_search_vector_update() RETURNS trigger AS $$
      BEGIN
        NEW.search_vector := to_tsvector('english', coalesce(NEW.body, ''));
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER posts_search_update
      BEFORE INSERT OR UPDATE ON posts
      FOR EACH ROW EXECUTE FUNCTION posts_search_vector_update();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS forum_threads_search_update ON forum_threads;
      DROP TRIGGER IF EXISTS posts_search_update ON posts;
      DROP FUNCTION IF EXISTS forum_threads_search_vector_update();
      DROP FUNCTION IF EXISTS posts_search_vector_update();
    SQL
    remove_column :forum_threads, :search_vector
    remove_column :posts,         :search_vector
  end
end
