#   Copyright (c) 2012-2015, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

require_relative '../test_helper'

describe HeartsController do
  describe 'POST Heart on libraries' do
    describe 'for non-signed-in users' do
      before :each do
        @library = FactoryGirl.create(:library)
        @library_2 = FactoryGirl.create(:library)
      end

      it 'should allow posting using ajax' do
        post :create, library_id: @library.id, format: :js
        assert_response :success
      end

      it 'change the heart count when posting' do
        assert_difference '@library.hearts.count', 1 do
          post :create, library_id: @library.id, format: :js
        end
      end

      it 'adds maximally one heart even when posting multiple times' do
        assert_difference '@library.hearts.count', 1 do
          3.times { post :create, library_id: @library.id, format: :js }
        end
      end

      it 'should allow hearting a second library' do
        assert_difference '@library_2.hearts.count', 1 do
          post :create, library_id: @library.id, format: :js
          post :create, library_id: @library_2.id, format: :js
        end
      end
    end

    describe 'for signed-in users' do
      before :each do
        @library = FactoryGirl.create(:library)
        @library_2 = FactoryGirl.create(:library)
        @user = FactoryGirl.create(:user)
        sign_in @user
      end

      it 'should allow posting using ajax' do
        post :create, library_id: @library.id, format: :js
        assert_response :success
      end

      it 'increases the heart count when posting' do
        assert_difference '@library.hearts.count', 1 do
          post :create, library_id: @library.id, format: :js
        end
      end

      it 'adds maximally one heart even when posting multiple times' do
        assert_difference '@library.hearts.count', 1 do
          3.times { post :create, library_id: @library.id, format: :js }
        end
      end

      it 'should allow hearting a second library' do
        assert_difference '@library_2.hearts.count', 1 do
          post :create, library_id: @library.id, format: :js
          post :create, library_id: @library_2.id, format: :js
        end
      end
    end
  end
  describe 'DELETE Heart on libraries' do
    describe 'for non-signed-in users' do
      before :each do
        @library = FactoryGirl.create(:library)
        @user = FactoryGirl.create(:user)
        @owned_heart = @library.hearts.create(heartable: @library, user: @user)
        @anonymous_heart = @library.hearts.create(heartable: @library,
                                                  user_token: 'RandomUserTokenThiswouldActuallyBeRandomData')
      end

      it 'will not delete an owned heart' do
        assert_difference '@library.hearts.count', 0 do
          delete :destroy, library_id: @library.id, id: @owned_heart.id
        end
      end

      it 'will not delete an anonymous heart' do
        assert_difference '@library.hearts.count', 0 do
          delete :destroy, library_id: @library.id, id: @anonymous_heart.id
        end
      end
    end

    describe 'for signed-in users' do
      before :each do
        @library = FactoryGirl.create(:library)
        @user = FactoryGirl.create(:user)
        sign_in @user
      end

      it 'will delete his own heart' do
        @owned_heart = @library.hearts.create(heartable: @library, user: @user)
        assert_difference '@library.hearts.count', -1 do
          delete :destroy, library_id: @library.id,
                           id: @owned_heart.id, format: :js
        end
      end

      it 'will not delete an anonymous heart' do
        @anonymous_heart = @library.hearts.create(heartable: @library,
                                                  user_token: 'RandomUserTokenThiswouldActuallyBeRandomData')
        assert_raises Pundit::NotAuthorizedError do
          delete :destroy, library_id: @library.id,
                           id: @anonymous_heart.id, format: :js
        end
      end

      it "will not delete someone else's heart" do
        @another_user = FactoryGirl.create(:user)
        @another_users_heart = @library.hearts.create(heartable: @library,
                                                      user: @another_user)
        assert_raises Pundit::NotAuthorizedError do
          delete :destroy, library_id: @library.id,
                           id: @another_users_heart.id, format: :js
        end
      end
    end
  end
end
