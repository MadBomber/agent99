# lib/agent99/header_management.rb

module Agent99::HeaderManagement


  ################################################
  # private
  
  def header      = @payload[:header]
  def to_uuid     = header[:to_uuid]
  def from_uuid   = header[:from_uuid]
  def event_uuid  = header[:event_uuid]
  def timestamp   = header[:timestamp]
  def type        = header[:type]

  def return_address
    return_address = payload[:header].dup

    return_address.merge(
      to_uuid:    return_address[:from_uuid],
      from_uuid:  return_address[:to_uuid],
      timestamp:  Agent99::Timestamp.new.to_i,
      type:       'response'
    )
  end
end
