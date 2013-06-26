class MoviesController < ApplicationController
  def directors
    director=Movie.find(params[:id])[:director]
    if (director== '') or (director== nil)
      redirect_to movies_path
      flash[:notice] = "'#{Movie.find_by_director(director)[:title]}' has no director info"
    else
      @movies=Movie.find_all_by_director(director)
    end
    @current_user ||= Moviegoer.find_by_id(session[:user_id])
  end

  def search_tmdb
    begin
      @movies=Movie.find_in_tmdb(params[:search_terms])
      if (@movies==[])
        flash[:warning] = "'#{params[:search_terms]}' was not found in TMDb."
        redirect_to movies_path
      end
      rescue Movie::InvalidKeyError => tmdb_error
        flash[:notice]="Search not available"
        redirect_to movies_path
    end
    @current_user ||= Moviegoer.find_by_id(session[:user_id])
  end

  def show
    id = params[:id] # retrieve movie ID from URI route
    @movie = Movie.find(id) # look up movie by unique ID
    # will render app/views/movies/show.<extension> by default
    @current_user ||= Moviegoer.find_by_id(session[:user_id])
  end

  def index
    sort = params[:sort] || session[:sort]
    case sort
    when 'title'
      ordering,@title_header = {:order => :title}, 'hilite'
    when 'release_date'
      ordering,@date_header = {:order => :release_date}, 'hilite'
    end
    @all_ratings = Movie.all_ratings
    @selected_ratings = params[:ratings] || session[:ratings] || {}
    
    if @selected_ratings == {}
      @selected_ratings = Hash[@all_ratings.map {|rating| [rating, rating]}]
    end
    
    if params[:sort] != session[:sort]
      session[:sort] = sort
      flash.keep
      redirect_to :sort => sort, :ratings => @selected_ratings and return
    end

    if params[:ratings] != session[:ratings] and @selected_ratings != {}
      session[:sort] = sort
      session[:ratings] = @selected_ratings
      flash.keep
      redirect_to :sort => sort, :ratings => @selected_ratings and return
    end
    @movies = Movie.find_all_by_rating(@selected_ratings.keys, ordering)
    @current_user ||= Moviegoer.find_by_id(session[:user_id])
  end

  def new
    # default: render 'new' template
  end

  def create

    if params[:movie]== nil
      if params[:rating]==nil
        params[:rating]='G'
      end
      @movie = Movie.create!(:title =>params[:title], :director=>params[:director], :rating=>params[:rating], :release_date=>params[:release_date])
    else
      @movie = Movie.create!(params[:movie])
    end
    flash[:notice] = "#{@movie.title} was successfully created."
    redirect_to movies_path
  end

  def edit
    @movie = Movie.find params[:id]
  end

  def update
    @movie = Movie.find params[:id]
    @movie.update_attributes!(params[:movie])
    flash[:notice] = "#{@movie.title} was successfully updated."
    redirect_to movie_path(@movie)
  end

  def destroy
    @movie = Movie.find(params[:id])
    @movie.destroy
    flash[:notice] = "Movie '#{@movie.title}' deleted."
    redirect_to movies_path
  end
end

