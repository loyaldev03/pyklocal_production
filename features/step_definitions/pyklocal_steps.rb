
# # sellet.feature  
Given(/^I am a user with email "([^"]*)" with password "([^"]*)"$/) do |email, password|
	role = Spree::Role.where(name:"merchant").first
 	Spree::User.create(email:"test@w3villa.com",password:"temp1234",password_confirmation:"temp1234",spree_role_ids:[role.id])
	steps %Q{
		When I go to the home page
	}
end

Given(/^I want to sign in as "([^"]*)" with password "([^"]*)"$/) do |email, password|
	steps %Q{
  	When I follow "Login"
    And I fill in "spree_user_email" with "test@w3villa.com"  
    And I fill in "spree_user_password" with "temp1234"
    And I press "Login"
	}
end

Given(/^I want to Apply for new store name "([^"]*)"$/) do |arg1|
	click_on"Sell with us"
	click_on"Apply For New Store"
end

Given(/^I fill the all the details for new store registration$/) do
	attach_file('merchant_store_logo', File.join(Rails.root, '/features/support/shop1.png'))
	steps %Q{
    And I fill in "merchant_store_name" with "Shopper & Stop" 
    And I fill in "merchant_store_manager_first_name" with "Gopal"
    And I fill in "merchant_store_manager_last_name" with "last" 
    And I fill in "merchant_store_phone_number" with "9879879879"
    And I fill in "merchant_store_site_url" with "www.shopperstop.com"
    And I fill in "merchant_store_street_number" with "captown city"
    And I fill in "merchant_store_city" with "noida-76"
    And I fill in "merchant_store_zipcode" with "201301"
    And I fill in "merchant_store_state" with "Utter pradesh"
    And I fill in "merchant_store_country" with "india"
	}
	find_field('Bag').click
	find_field('Clothing').click
	click_on"Create" 
end

Given(/^I should add a new product "([^"]*)" with price "([^"]*)"$/) do |name, price|
	click_on"Add Product"
	fill_in('product_name',:with => name)
	fill_in('product_price',:with => price)
	page.execute_script(%{$("#product_available_on").val('2016/12/20')});
	select("Default", :from =>"product_shipping_category_id" )
	click_on"Save"
	page.execute_script(%{$("#products div:contains('fila shoes') .buy-now a:contains('Edit')")});
	debugger
  
end

Given(/^I should check product is added in product shop page$/) do
	click_on"Go to store"
	page.evaluate_script(%{$("#products .product-item ").length}).should == 1
	# click_on"All Categories"
	# page.evaluate_script(%{$(".product-layout .product-grid ").length}).should == 1

  
end

Given(/^I want to update product "([^"]*)" details with Image$/) do |image|
  click_on"Edit"  
  click_on"IMAGES"
  click_on"Add new image"
  attach_file('image_attachment', File.join(Rails.root, '/features/support/iphone.jpg'))
  click_on"Create"
  click_on"All Categories"
	page.evaluate_script(%{$(".product-layout .product-grid ").length}).should == 1


end
Given(/^I want to also update stock managment with quantity "([^"]*)"$/) do |stock|
debugger
	# click_on"Go to store"
 #  click_on"Edit"
 #  debugger
 #  click_on"STOCK MANAGMENT"
 #  fill_in('stock_movement_quantity',:with => stock)
end

Then(/^I should break$/) do
  debugger
end
