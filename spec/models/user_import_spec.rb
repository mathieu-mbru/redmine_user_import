require "rails_helper"
require "spec_helper"

# for add the folder of fixture in the same plugin
RSpec.configure do |config|
  config.fixture_path = __dir__+"/../fixtures"
end

def uploaded_test_file(name, mime)
  fixture_file_upload("files/#{name}", mime, true)
end

def generate_import(fixture_name='import_users.csv')
  import = UserImport.new
  import.user_id = 2
  import.file = uploaded_test_file(fixture_name, 'text/csv')
  import.save!
  import
end

def generate_import_with_mapping(fixture_name='import_users.csv')
  import = generate_import(fixture_name)

   import.settings = {
     'separator' => ";", 'wrapper' => '"', 'encoding' => "UTF-8", "notifications"=>"0",
     'mapping' => {"login"=>"0", "firstname"=>"2", "lastname"=>"1", "mail"=>"3", "organization"=>"4", "create_organizations"=>"0"},
   }
   import.save!
   import
end

RSpec.describe UserImport, type: :model do
    fixtures :users, :email_addresses,:members , :member_roles, :roles, :projects, :organizations

    it "should_update_organization_of_users" do   
      import = generate_import_with_mapping
      import.save!
      import.run
      # test update Organization
      expect(User.all[-2].organization_id).to eq (1) 
      expect(User.last.organization_id).to eq (nil) 
    end

    it "should_not_import_user_already_existed" do
      user_count_before = User.count
      import = generate_import_with_mapping('import_users_exists.csv')
      import.save!
      import.run
      user_count_after = User.count

      expect(ImportItem.first.message).to eq("Email has already been taken\nLogin has already been taken")

      expect(user_count_before).to eq(user_count_after - 1)
      # update user's organization
      expect(User.find(3).organization_id).to eq(1)

    end

  it "should_remove_the_file" do
    import = generate_import_with_mapping
    file_path = import.filepath
    assert File.exists?(file_path)

    import.run
    assert !File.exists?(file_path)
  end

end
