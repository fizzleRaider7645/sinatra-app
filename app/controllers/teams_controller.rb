class TeamsController < ApplicationController
  get '/teams' do
    if logged_in?
      erb :'teams/index'
    else
      redirect :'/login'
    end
  end

  post '/teams' do
    if logged_in?
      @team = Team.new(params)
      if @team.save
        @team.user_id = current_user.id
        @team.roster_spots = 5
        @team.save
        redirect :'/show'
      else
        @errors = @team.errors
        redirect :'teams/new'
      end
    #   @team = Team.create(params)
    #   @team.user_id = current_user.id
    #   @team.roster_spots = 5
    #   @team.save
    #   redirect :'/show'
    # else
    #   redirect :'/login'
    end
  end

  get '/teams/new' do
    if logged_in?
      @players = Player.all
      erb :'teams/new'
    else
      redirect :'/login'
    end
  end

  get '/teams/show/:id' do
    #check if logged in
    if logged_in?
      @team = Team.find(params[:id])
      erb :'teams/show'
    else
      redirect :'/login'
    end
  end

  get '/teams/:id/edit' do
    @team = Team.find(params[:id])
    if logged_in? && @team.user_id == current_user.id
      @players = Player.all.uniq { |player| player.name }.select { |player| player.team_id == current_user.team.id || player.team_id == nil }
      erb :'teams/edit'
    else
      redirect :'/login'
    end
  end


  patch '/teams/:id/edit' do
    if logged_in?
      #team name edit check
      if params[:team_name] != ""
        @team = current_user.team
        @team.update(name: params[:team_name])
      end
      #end of team name edit check

      #custom player check
      if params[:custom_player_name] != ""
        @custom_player = Player.create(name: params[:custom_player_name])

        #in case of a custom player being created
        #and no params[:player_ids] / clear all previously checked players
        if params[:player_ids].nil?
          current_user.team.players.clear
        end

        current_user.team.players << @custom_player unless current_user.team.at_max?

        #reset and adjust the team roster_spots count
        current_user.team.roster_spots = 5
        current_user.team.roster_spots -= current_user.team.players.count
        current_user.team.save
      end
      #end of custom player check

#**************CHECKBOX LOGIC START********************************************

      #When no players are checked and no custom player / remove all players from team
      if params[:player_ids] == nil && params[:custom_player_name] == ""
        current_user.team.players.clear
        #reset and adjust the team roster_spots
        current_user.team.roster_spots = 5
        current_user.team.save
      end
        #end of no custom player && params check

      #When there are checked players
      if params[:player_ids]
        current_ids = current_user.team.players.map { |player| player.id }
        incoming_ids = params[:player_ids].map(&:to_i)

        #the following if statement is needed in case of custom player and checked players
        incoming_ids << @custom_player.id if @custom_player

        #iterating throught current_ids
        #to check to see if we have a current player not included in incoming_ids
        current_ids.each do |id|
          #if id in current_ids is not included in incoming_ids then set player.team_id
          #to nil
          if !incoming_ids.include?(id)
            @former_player = Player.find(id)
            @former_player.team_id = nil
            @former_player.save
          end
        end

        #iterating over incoming_ids as these players should be on roster
        incoming_ids.each do |id|
          @player = Player.find(id)
          @player.team_id = current_user.team.id unless current_user.team.at_max?
          @player.save
        end
        #reset and adjust the team roster_spots count
        current_user.team.roster_spots = 5
        current_user.team.roster_spots -= current_user.team.players.count
        current_user.team.save
        redirect :'/show'
      end
      #end of check when there are checked players and players currently on roster
    else
      redirect :'/login'
    end
    redirect :'/show'
    #**************CHECKBOX LOGIC END********************************************
  end

  delete '/teams/:id/delete' do
    @team = Team.find(params[:id])
    if logged_in? && @team.id == current_user.team.id
      @team.players.clear
      Team.delete(@team.id)
      redirect :'/show'
    else
      redirect :'/login'
    end
  end
end
