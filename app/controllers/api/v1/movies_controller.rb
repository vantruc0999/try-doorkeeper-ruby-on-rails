class Api::V1::MoviesController < ApiController
    before_action :set_movie, only: %i[ show update destroy ]
    skip_before_action :doorkeeper_authorize!, only: %i[index show]
    before_action :is_admin?, only: %i[create update destroy]

    include ApplicationHelper
    include ApiResponse

    # GET /movies or /movies.json
    # This code includes user object in ratings
    # def index
    #     @movies = Movie.includes(:genres).all
    #     render json:{
    #         status: 'Success',
    #         message: "Movies load successfully",
    #         data: @movies.as_json(
    #           include: { 
    #             genres: { except: [:created_at, :updated_at] },
    #             rating: {
    #               include: {
    #                 user: { only: [:id, :name, :email] } # Include user details
    #               },
    #               except: [:created_at, :updated_at]
    #             } 
    #           },
    #         ),
    #     }, status: :ok
    # end
    
    # this code does not include user object in ratings, user infor is in ratings section
    def index
      @movies = Movie.includes(:genres, ratings: :user).all
      data = @movies.map do |movie|
        {
          id: movie.id,
          title: movie.title,
          poster: movie.poster,
          introduction: movie.introduction,
          director: movie.director,
          story: movie.story,
          language: movie.language,
          release_date: movie.release_date,
          genres: movie.genres.map { |genre| genre.attributes.except('created_at', 'updated_at') },
          ratings: movie.ratings.map do |item|
            {
              id: item.id,
              user_id: item.user.id,
              name: item.user.name,
              email: item.user.email,
              rating_value: item.rating_value,
              comment: item.comment
            }
          end,
          average_rating: movie.ratings.average(:rating_value),
          comments_count: movie.ratings.count { |rating| rating.comment.present? }
        }
      end

      render_success(data, 'Movies loaded successfully')

    end
    
    # GET /movies/1 or /movies/1.json
    def show
      data = @movie.as_json(include: { genres: { except: [:created_at, :updated_at] } })
      render_success(data, 'Movies loaded successfully')
    end
  
    # POST /movies or /movies.json
    def create
        @movie = Movie.new(movie_params)
      
        if @movie.save
          params[:genres].each do |genre_id|
            genre = Genre.find_or_create_by(id: genre_id)
            @movie.genres << genre
          end
          render_success(@movie,  "Movie created successfully")
        else
          render_error( @movie.errors)
        end

    end
      
  
    # PATCH/PUT /movies/1 or /movies/1.json
    def update      
        if @movie.update(movie_params)
          @movie.genres.clear
      
          params[:genres].each do |genre_id|
            genre = Genre.find_or_create_by(id: genre_id)
            @movie.genres << genre
        end
          render_success(@movie, "Movie updated successfully")
        else
          render_error(@movie, @movie.errors)
        end
    end
      
    # DELETE /movies/1 or /movies/1.json
    def destroy
        @movie.destroy
        render_success(@movie, "Movie deleted successfully")
    end
  
    private
      # Use callbacks to share common setup or constraints between actions.
      def set_movie
        @movie = Movie.find_by(id: params[:id])

        if !@movie
            render json: {
                status: :unprocessable_entity,
                message: "Movie not found"
        }, status: :unprocessable_entity
        end
      end
  
      # Only allow a list of trusted parameters through.
      def movie_params
        params.require(:movie).permit(:title, :director, :release_date, :language, :story, :poster, :introduction, :genres)
      end
  end
  