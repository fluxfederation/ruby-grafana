
module Grafana

  # http://docs.grafana.org/http_api/team/
  #
  # This API can be used to create/update/delete Teams and to add/remove users to Teams.
  # All actions require that the user has the Admin role for the organization.
  #
  module Teams

    # http://docs.grafana.org/http_api/team/#team-search-with-paging
    #
    # GET /api/teams/search?perpage=50&page=1&query=myteam
    # or
    # GET /api/teams/search?name=myteam
    #
    # Default value for the perpage parameter is 1000 and for the page parameter is 1.
    #
    # The totalCount field in the response can be used for pagination of the teams list E.g. if totalCount is equal to 100 teams and the perpage parameter is set to 10 then there are 10 pages of teams.
    #
    # The query parameter is optional and it will return results where the query value is contained in the name field. Query values with spaces need to be url encoded e.g. query=my%20team.
    #
    # The name parameter returns a single team if the parameter matches the name field.



    #
    # Status Codes:
    #
    # 200 - Ok
    # 401 - Unauthorized
    # 403 - Permission denied
    # 404 - Team not found (if searching by name)
    #
    def search_team( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      perpage = validate( params, required: false, var: 'perpage', type: Integer ) || 1000
      page    = validate( params, required: false, var: 'page'   , type: Integer ) || 1
      query   = validate( params, required: false, var: 'query'  , type: String )
      name    = validate( params, required: false, var: 'name'   , type: String )

      unless(name.nil?)
        endpoint = format('/api/teams/search?name=%s',CGI.escape(name))
      else

        api     = []
        api << format( 'perpage=%s', perpage ) unless( perpage.nil? )
        api << format( 'page=%s', page ) unless( page.nil? )
        api << format( 'query=%s', CGI.escape( query ) ) unless( query.nil? )

        api = api.join( '&' )

        endpoint = format('/api/teams/search?%s', api)
      end

      @logger.debug("Attempting to search for alerts (GET #{endpoint})") if @debug

      r = get(endpoint)
      r['status'] = 404 if( r.dig('totalCount') == 0 )
      r
    end

    # http://docs.grafana.org/http_api/team/#get-team-by-id
    #
    # Get Team By Id
    # GET /api/teams/:id
    #
    #
    def team( team_id )

      raise ArgumentError.new(format('wrong type. user \'team_id\' must be an String (for an Team name) or an Integer (for an Team Id), given \'%s\'', team_id.class.to_s)) if( team_id.is_a?(String) && team_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'team_id\'') if( team_id.size.zero? )

      if(team_id.is_a?(String))
        o_team = search_team(name: team_id)
        status      = o_team.dig('status')
        total_count = o_team.dig('totalCount')

        if(status == 200 && total_count > 0)
          teams = o_team.dig('teams')
          team  = teams.detect { |v| v['name'] == team_id }

          team_id = team.dig('id')
        else
          return { 'status' => 404, 'message' => format( 'No Team \'%s\' found', team_id) }
        end
      end

      endpoint = format( '/api/teams/%s', team_id )

      @logger.debug("Getting team by Id #{team_id} (GET #{endpoint})") if @debug
      get(endpoint)
    end

    # http://docs.grafana.org/http_api/team/#add-team
    #
    # The Team name needs to be unique. name is required and email is optional.
    # POST /api/teams
    #
    #
    def add_team( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      name  = validate( params, required: true, var: 'name'  , type: String )
      email = validate( params, required: false, var: 'email', type: String )

      o_team = search_team(name: name)

      status      = o_team.dig('status')
      total_count = o_team.dig('totalCount')

      if(status == 200 && total_count > 0)
        teams = o_team.dig('teams')
        team  = teams.detect { |v| v['name'] == name }

        return {
          'status' => 404,
          'message' => format('team \'%s\' alread exists', name)
        }
      end

      endpoint = '/api/teams'

      payload = {
        name: name,
        email: email
      }
      payload.reject!{ |_k, v| v.nil? }

      @logger.debug("Creating teal: #{name} (POST #{endpoint})") if @debug

      post( endpoint, payload.to_json )
    end

    # http://docs.grafana.org/http_api/team/#update-team
    #
    # There are two fields that can be updated for a team: name and email.
    # PUT /api/teams/:id
    #
    def update_team( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      name     = validate( params, required: true , var: 'name'    , type: String )
      new_name = validate( params, required: true , var: 'new_name', type: String )
      email    = validate( params, required: false, var: 'email'   , type: String )


    end

    # http://docs.grafana.org/http_api/team/#delete-team-by-id
    #
    # DELETE /api/teams/:id
    #
    #
    #
    #
    #
    #
    def delete_team(team_id)

      raise ArgumentError.new(format('wrong type. user \'team_id\' must be an String (for an Team name) or an Integer (for an Team Id), given \'%s\'', team_id.class.to_s)) if( team_id.is_a?(String) && team_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'team_id\'') if( team_id.size.zero? )

      if(team_id.is_a?(String))
        o_team = search_team(name: team_id)

        status      = o_team.dig('status')
        total_count = o_team.dig('totalCount')

        if(status == 200 && total_count > 0)
          teams = o_team.dig('teams')
          team  = teams.detect { |v| v['name'] == team_id }

          team_id = team.dig('id')
        end
      end

      endpoint = format( '/api/teams/%s', team_id )

      @logger.debug("delete team Id #{team_id} (GET #{endpoint})") if @debug
      delete(endpoint)
    end

    # http://docs.grafana.org/http_api/team/#get-team-members
    #
    # GET /api/teams/:teamId/members
    #
    #
    #
    #
    def team_members(team_id)

      raise ArgumentError.new(format('wrong type. user \'team_id\' must be an String (for an Team name) or an Integer (for an Team Id), given \'%s\'', team_id.class.to_s)) if( team_id.is_a?(String) && team_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'team_id\'') if( team_id.size.zero? )

      if(team_id.is_a?(String))
        o_team = search_team(name: team_id)

        status      = o_team.dig('status')
        total_count = o_team.dig('totalCount')

        if(status == 200 && total_count > 0)
          teams = o_team.dig('teams')
          team  = teams.detect { |v| v['name'] == team_id }

          team_id = team.dig('id')
        else
          return { 'status' => 404, 'message' => format( 'No Team \'%s\' found', team_id) }
        end
      end

      endpoint = format( '/api/teams/%s/members', team_id )

      @logger.debug("Getting team by Id #{team_id} (GET #{endpoint})") if @debug

      get(endpoint)
    end

    # http://docs.grafana.org/http_api/team/#add-team-member
    #
    # POST /api/teams/:teamId/members
    #
    #
    #
    def add_team_member()


    end

    # http://docs.grafana.org/http_api/team/#remove-member-from-team
    #
    # DELETE /api/teams/:teamId/members/:userId
    #
    #
    #
    def remove_team_meber()


    end

  end
end
