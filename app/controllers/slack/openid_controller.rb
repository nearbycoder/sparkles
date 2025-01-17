module Slack
  class OpenIDController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:callback]

    before_action :verify_state

    def callback
      slack_client = Slack::Web::Client.new
      response = slack_client.post('openid.connect.token', {
        code: params[:code],
        client_id: Rails.application.credentials.dig(:slack, :client_id),
        client_secret: Rails.application.credentials.dig(:slack, :client_secret),
        redirect_uri: slack_openid_callback_url,
      })

      # Parse the JWT we received and validate its nonce
      jwt, _ = JWT.decode(response.id_token, nil, false)
      if jwt["nonce"] != cookies.encrypted[:nonce]
        flash.alert = "The provided OpenID nonce did not match. Please try signing in again."

        redirect_to root_path and return
      end

      # Make sure the team has installed Sparkles
      unless ::Team.where(slack_id: jwt["https://slack.com/team_id"]).exists?
        flash.alert = "Oops, your team hasn't installed Sparkles yet! Use the \"Add to Slack\" button to get it installed before trying to sign in."

        redirect_to root_path and return
      end

      user = ::User.find_or_create_by!(slack_team_id: jwt["https://slack.com/team_id"], slack_id: jwt["https://slack.com/user_id"])

      cookies.encrypted.permanent[:slack_team_id] = user.slack_team_id
      cookies.encrypted.permanent[:slack_user_id] = user.slack_id

      redirect_to root_path
    end

    private

    def verify_state
      if cookies.encrypted[:state] != params[:state]
        flash.alert = "The provided OAuth state did not match. Please try installing to Slack again."

        redirect_to root_path
      end
    end
  end
end
