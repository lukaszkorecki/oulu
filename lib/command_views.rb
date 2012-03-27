# Render static parameters to IRC protocol strings.
module CommandViews
  def render_notice(sender_host, target, text)
    ":#{sender_host} NOTICE #{target} :#{text}"
  end

  def render_join(channel)
    ":#{user_irc_host} JOIN :#{channel}"
  end

  def render_mode(sender_host, target, mode)
    ":#{sender_host} MODE #{target} :#{mode}"
  end

  def render_end_of_ban_list(channel)
    server_msg("368", channel, "End of Channel Ban List")
  end

  def render_channel_modes(channel, modes)
    server_msg("324", channel, modes.to_s)
  end

  def render_names_nicks(channel, nicks)
    server_msg("353", "@", channel, nicks.join(' '))
  end

  def render_names_end(channel)
    server_msg("366", channel, "End of NAMES list")
  end

  def render_nick(old_host, new_nick)
    ":#{old_host} NICK :#{new_nick}"
  end

  def render_nick_error(new_nick)
    server_msg("432", new_nick, "Erroneous nickname")
  end

  def render_ping(value)
    "PING :#{value}"
  end

  def render_pong(value)
    "PONG :#{value}"
  end

  def render_privmsg(sender_host, target, text)
    ":#{sender_host} PRIVMSG #{target} :#{text}"
  end

  def render_quit(message = "leaving")
    "ERROR :Closing Link: #{user_nick}[#{user_email}] (\"#{message}\")"
  end

  def render_whois(nick, email, realname, idle_seconds, signon_timestamp)
    email_info = email.split('@').join(' ')

    [ [311, "#{email_info} * :#{realname}"],
      [312, "#{server_host} :#{IrcServer::NAME}"],
      [317, "#{idle_seconds.to_i} #{signon_timestamp.to_i} :seconds idle, signon time"],
      [318, ":End of WHOIS list."] ].map do |code, text|
        ":#{server_host} #{code} #{user_nick} #{nick} #{text}"
    end.join("\r\n")
  end

  def render_no_such_nick(nick)
    server_msg(401, nick, "No such nick/channel")
  end

  ## MOTD

  def render_welcome
    server_msg("001", "Welcome to the Internet Relay Network #{user_irc_host}")
  end

  def render_yourhost
    server_msg("002", "Your host is #{server_host}, running version 1.0")
  end

  def render_created
    server_msg("003", "This server was created just moments ago")
  end

  def render_motd_start
    server_msg("375", "- #{server_host} Message of the day - ")
  end

  def render_motd_line(text)
    server_msg("372", "- #{text}")
  end

  def render_motd_end
    server_msg("376", "End of MOTD command")
  end

  ## Helpers

  def server_msg(code, *args)
    last = ":#{args.pop}"
    text = (args + [last]).join(' ')
    ":#{server_host} #{code} #{user_nick} #{text}"
  end
end