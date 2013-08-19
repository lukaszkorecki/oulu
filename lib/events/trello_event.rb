class TrelloEvent < FlowdockEvent
  register_event "trello"

  def render
    rss_text = team_inbox_event("Trello", TrelloEvent.new(@message["content"]).process.subject)
    render_notice(IrcServer::FLOWDOCK_USER, @target.irc_id, rss_text)
  end

  def valid?
    channel?
  end
end

class TrelloEventParser
  attr_reader :source,
                :from_address,
                :subject,
                :content,
                :from,
                :project,
                :card_link

  def initialize result
    @result = result
  end

  # TODO clean this up....
  def process
    data = @result['data']
    @source = 'Trello'
    @from = @result['memberCreator']['fullName']
    @project = data['board']['name']

    @board_id = data['board']['id']
    @board_link = "https://trello.com/board/#{@board_id}"

    card_data = data['card'] || {}
    @card_link = "https://trello.com/card/#{@board_id}/#{card_data['idShort']}"
    card_name = card_data['name']
    @subject, @content = process_event @result, card_name
    self
  end

  def process_event result, card_name
    data = result['data']

    case result['type']
    when 'addMemberToCard'
      subject = "Added #{result['member']['fullName']} to: #{card_name}"
      raw_content = card_name
    when 'commentCard'
      subject = "Commented on: #{card_name}"
      raw_content = data['text']
    when 'createCard'
      subject = "Created: #{card_name}"
      raw_content = card_name
    when 'removeMemberFromCard'
      subject = "Removed #{result['member']['fullName']} from: #{card_name}"
      raw_content = card_name
    when 'updateCard'
      if data['listAfter'] && data['listBefore']['name'] != data['listAfter']['name']
        subject = "Moved to #{data['listAfter']['name']}: #{card_name}"
      elsif data['old'] && data['old']['desc']
        subject = "Updated description for: #{card_name}"
      elsif data['old'] && data['old']['name']
        subject = "Updated name for: #{card_name}"
      elsif data['old'] && !data['old']['closed'].nil?
        if data['old']['closed']
          subject = "Reopened: #{card_name}"
        else
          subject = "Archived: #{card_name}"
        end
      end
      raw_content = data['card']['desc'] || 'Updated'
    when 'updateCheckItemStateOnCard'
      subject = "Updated #{data['checkItem']['name']} on: #{card_name}"
      raw_content = "State: #{data['checkItem']['state'] || 'incomplete'}"
    end

    return subject, text_to_html(raw_content)
  end

  def text_to_html(text)
    start_tag = '<p>'
    text = text.to_str
    text.gsub!(%r/\r\n?/, "\n")
    text.gsub!(%r/\n\n+/, "</p>\n\n#{start_tag}")
    text.gsub!(%r/([^\n]\n)(?=[^\n])/, '\1<br />')
    text.insert 0, start_tag
    text << '</p>'
  end

end
