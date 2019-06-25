require 'spec_helper_acceptance'

describe 'ios_network_trunk' do
  before(:all) do
    # Remove if already present
    # NOTE That this will fail on a 2960
    # as switchport is always on
    pp = <<-EOS
    ios_network_trunk { 'Port-channel1':
      ensure => 'absent',
    }
    EOS
    make_site_pp(pp)
    run_device(allow_changes: true)
  end

  it 'add a network trunk' do
    pp = <<-EOS
    ios_network_trunk { 'Port-channel1':
      ensure => 'present',
      mode => 'access',
    }
    EOS
    make_site_pp(pp)
    run_device(allow_changes: true)
    # Are we idempotent
    run_device(allow_changes: false)
    # Check puppet resource
    result = run_resource('ios_network_trunk', 'Port-channel1')
    expect(result).to match(%r{Port-channel1.*})
    expect(result).to match(%r{mode.*access})
    expect(result).to match(%r{ensure.*present})
  end

  it 'edit an existing trunk' do
    pp = <<-EOS
    ios_network_trunk { 'Port-channel1':
      ensure => 'present',
      encapsulation => 'dot1q',
      mode => 'trunk',
      untagged_vlan => 42,
      access_vlan => 8,
      switchport_nonegotiate => true,
    }
    EOS
    
    make_site_pp(pp)
    run_device(allow_changes: true)
    # Are we idempotent
    run_device(allow_changes: false)
    # Check puppet resource
    result = run_resource('ios_network_trunk', 'Port-channel1')
    expect(result).to match(%r{'Port-channel1'})
    # Not set/read on a 2960
    expect(result).to match(%r{encapsulation => 'dot1q'}) if result =~ %r{encapsulation =>}
    expect(result).to match(%r{mode => 'trunk'})
    expect(result).to match(%r{untagged_vlan => 42})
    expect(result).to match(%r{access_vlan => 8})
    expect(result).to match(%r{ensure => 'present'})
    expect(result).to match(%r{switchport_nonegotiate => true})
  end

  # it 'edit an existing trunk - voice vlan' do
  #   # Can only be set on certain vlans. Does not work on Port-channel1
  #   pp = <<-EOS
  #   ios_network_trunk { 'GigabitEthernet1/0/24':
  #     ensure => 'present',
  #     voice_vlan => '97'
  #   }
  #   EOS
    
  #   make_site_pp(pp)
  #   run_device(allow_changes: true)
  #   # Are we idempotent
  #   run_device(allow_changes: false)
  #   # Check puppet resource
  #   result = run_resource('ios_network_trunk', 'GigabitEthernet1/0/24')
  #   expect(result).to match(%r{GigabitEthernet1/0/24.*})
  #   expect(result).to match(%r{untagged_vlan.*42})
  # end

  it 'remove an existing interface' do
    # NOTE That this will fail on a 2960
    # as switchport is always on
    pp = <<-EOS
    ios_network_trunk { 'Port-channel1':
      ensure => 'absent',
    }
    EOS
    make_site_pp(pp)
    run_device(allow_changes: true)
    # Are we idempotent
    run_device(allow_changes: false)
    # Check puppet resource
    result = run_resource('ios_network_trunk', 'Port-channel1')
    expect(result).to match(%r{Port-channel1.*})
    # Cannot currently test
    # expect(result).to match(%r{ensure.*absent})
  end
end
