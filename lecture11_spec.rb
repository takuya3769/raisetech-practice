require 'spec_helper'

describe user('ec2-user') do
  it { should exist }
end

describe port(22) do
  it { should be_listening.with('tcp') }
end

describe port(80) do
  it { should be_listening }
end

describe command('ruby -v') do
  its(:stdout) { should match /ruby 3.1.2p20*/ }
end

describe command('rails -v') do
  its(:stdout) { should match /Rails 7.0.4/ }
end

describe package('nginx') do
  it { should be_installed }
end
