module Slack
  module Events
    # We receive this event any time a user joins a channel; however, we only
    # care about processing it when the user is Sparklebot and the channel is
    # private. In this case, it means Sparklebot was invited to a private
    # channel and we need to store it in our local cache.
    class MemberJoinedChannel < Base
      def handle
        return unless payload[:user] == team.sparklebot_id

        response = team.api_client.conversations_info(channel: payload[:channel])
        slack_channel = Slack::Channel.from_api_response(response.channel)

        return unless slack_channel.private?

        ::Channel.upsert(slack_channel.attributes, unique_by: [:slack_team_id, :slack_id])
      end
    end
  end
end
