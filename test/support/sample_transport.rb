# frozen_string_literal: true

# Every Transport::NetHttp, including the ones that documentation samples
# and examples create through their own clients, sends to the fake given to
# SampleTransport.using instead of the network.
module SampleTransport
  KEY = :teachmehipaa_sample_transport

  def self.using(fake)
    Thread.current[KEY] = fake
    yield
  ensure
    Thread.current[KEY] = nil
  end

  def call(request, &)
    fake = Thread.current[KEY]
    return super if fake.nil?

    fake.call(request, &)
  end
end
TeachMeHipaa::Transport::NetHttp.prepend(SampleTransport)
