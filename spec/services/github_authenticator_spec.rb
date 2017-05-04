require 'rails_helper'

RSpec.describe GithubAuthenticator do
  let(:authenticator) { GithubAuthenticator.new(auth) }

  describe 'test' do
    let(:user) { Fabricate.build(:user) }
    it { expect(user).to be_valid }
  end

  describe '#authenticate' do
    let(:auth) do
      {
        'uid' => 'testuid',
        'privider' => 'testprovider',
        'credentials' => 'testtoken',
        'info' => {
          'email' => 'test@test.com',
          'nickname' => 'testnickname',
          'name' => 'testname',
          'image' => 'http://test.com/image.png',
          'bio' => 'testbio'
        }
      }
    end

    before do
      expect_any_instance_of(Account).to receive(:avatar_remote_url=)
    end

    let(:user) { authenticator.authenticate }

    describe 'new user' do
      describe 'perfect data' do
        it { expect(user.persisted?).to be_truthy }
      end

      describe 'nickname' do
        describe 'absence' do
          before { auth['info'].delete 'nickname' }

          it { expect(user.persisted?).to be_truthy }

          it 'should have uid for account.username' do
            expect(user.account.username).to eql'testuid'
          end
        end

        describe 'too long' do
          before { auth['info']['nickname'] = 'a' * 60 }

          it { expect(user.persisted?).to be_truthy }
          it { expect(user.account.username).to eql'a' * 30 }
        end

        describe 'upcase' do
          before { auth['info']['nickname'] = 'UPCASE'}

          it { expect(user.persisted?).to be_truthy }
          it { expect(user.account.username).to eql'upcase' }
        end

        describe 'hyphen' do
          before { auth['info']['nickname'] = 'test-test'}

          it { expect(user.persisted?).to be_truthy }
          it { expect(user.account.username).to eql'test_test' }
        end
      end

      describe 'name' do
        describe 'absence' do
          before { auth['info'].delete 'name' }

          it { expect(user.persisted?).to be_truthy }

          it 'should have account.username for account.display_name' do
            expect(user.account.display_name).to eql'testnickname'
          end
        end

        describe 'too long' do
          before { auth['info']['name'] = 'a' * 60 }

          it { expect(user.persisted?).to be_truthy }
          it { expect(user.account.display_name).to eql'a' * 30 }
        end
      end

      describe 'bio' do
        describe 'absence' do
          before { auth['info'].delete 'bio' }

          it { expect(user.persisted?).to be_truthy }

          it 'should have blank' do
            expect(user.account.note).to eql''
          end
        end

        describe 'too long' do
          before { auth['info']['bio'] = 'a' * 260 }

          it { expect(user.persisted?).to be_truthy }
          it { expect(user.account.note).to eql'a' * 157 + '...' }
        end
      end
    end
  end
end
