And(/^I visit the edit slug page for "([^"]*)"$/) do |edition_title|
  @edition = Edition.find_by!(title: edition_title)
  visit edit_slug_admin_edition_path(@edition)
end

And(/^I update the slug to "([^"]*)"$/) do |new_slug|
  fill_in "Slug", with: new_slug
  click_button "Update"
end

Then(/^I can see the edition's public URL contains "([^"]*)"$/) do |new_slug|
  visit admin_edition_path(@edition)
  click_button "Create new edition"
  expect(page.find(".app-view-edit-edition__page-address .govuk-hint")).to have_content new_slug
end

Then(/^I am told I do not have access to the document$/) do
  expect(page).to have_content "Sorry, you don’t have access to this document"
end
