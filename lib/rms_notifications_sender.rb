# sender_id = 0 if system notification

# source:
# 1   feeds
# 2   fanpage
# 3   gamepage
# 4   sdk
# 5   用户登录
# 6   用户支付 wallet
# 7   异常登录
# 8   用户评论
# 9   用户资料 profile settings
# 10  好友 friend request
# 11  等级 level
# 12  徽章 badges

# msgTypeId 如下
# 1	  留言
# 2	  视频
# 3	  图片
# 4	  点赞
# 5	  添加好友 friend request
# 7	  添加feeds时@提醒
# 8	  添加comment时@提醒
# 9	  邀请通知
# 10  徽章 badges
# 11  个人资料 profile settings
# 12  钱包 wallet
# 13  等级 level

class RmsNotificationsSender
  attr_accessor :content, :user_id, :type, :sender_id

  def initialize(content:, user_id:, type:, sender_id: 0)
    self.content = content
    self.user_id = user_id
    self.type = type
    self.sender_id = sender_id
  end

  def send
    url = "#{Rails.application.secrets.notification_server_url}/notification/saveNotification"
    feedsId = ""

    case type
    when "badge_received"
      msgTypeId = 10
      sourceType = 12
    when "account_activation"
      msgTypeId = 11
      sourceType = 9
    when "level_up"
      msgTypeId = 13
      sourceType = 11
    when "rpoint_received"
      msgTypeId = 12
      sourceType = 6
    when "friend_request"
      msgTypeId = 5
      sourceType = 10
    when "password_change"
      msgTypeId = 11
      sourceType = 9
    when "account_id_change"
      msgTypeId = 11
      sourceType = 9
    end

    if check_notification_settings_for(user_id, type)
      response = RestClient.post(
        url,
        {
          content: content,
          msgTypeId: msgTypeId,
          source: sourceType,
          userId: user_id,
          senderUserId: sender_id,
          feedsId: feedsId
        }.to_json,
        content_type: :json
      )
      json_response = JSON.parse(response.body)
      if json_response["code"] != "0"
        Rails.logger.error "Send notification: #{json_response["message"]}".red
        false
      else
        true
      end
    end
  end

  private

  def check_notification_settings_for(user_id, type=nil)
    url = "#{Rails.application.secrets.notification_server_url}/profile/setting/notification/#{user_id}"
    response = RestClient.get(url)
    json_response = JSON.parse(response.body)

    result = 1
    case type
    when "friend_request"
      result = json_response["data"]["isAddFriendNotified"]
    end
    return result == 1
  end
end
