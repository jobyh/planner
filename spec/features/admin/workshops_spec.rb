require 'spec_helper'

RSpec.feature 'Managing workshops', type: :feature do
  let(:member) { Fabricate(:member) }
  let!(:chapter) { Fabricate(:chapter) }
  let!(:sponsor) { Fabricate(:sponsor) }

  before do
    login_as_admin(member)
    member.add_role(:organiser, Chapter)
  end

  scenario 'viewing list of all chapter workshops' do
    workshops = Fabricate.times(5, :workshop, chapter: chapter)
    visit admin_chapter_workshops_path(chapter)

    workshops.each do |workshop|
      expect(page).to have_content(humanize_date(workshop.date_and_time, with_time: true))
    end
  end

  context 'creating a new workshop' do
    scenario 'successfully' do
      visit new_admin_workshop_path

      select chapter.name
      fill_in 'Date', with: Date.current
      fill_in 'Begins at', with: '11:30'

      click_on 'Save'

      expect(page).to have_content('The workshop has been created')
      expect(page).to have_content 'Invite'
    end

    scenario 'with ends_at' do
      visit new_admin_workshop_path

      select chapter.name
      fill_in 'Date', with: Date.current
      fill_in 'Begins at', with: '11:30'
      fill_in 'Ends at', with: '12:45'

      click_on 'Save'

      expect(page).to have_content('The workshop has been created')
      expect(page).to have_content '11:30 - 12:45'
    end

    scenario 'renders an error when no chapter has been selected' do
      visit new_admin_workshop_path

      fill_in 'Date', with: Date.current
      fill_in 'Begins at', with: '11:30'

      click_on 'Save'

      expect(page).to have_content('Chapter can\'t be blank')
    end
  end

  scenario 'assigning a host to a workshop' do
    workshop = Fabricate(:workshop_no_sponsor)
    visit edit_admin_workshop_path(workshop)

    select sponsor.name, from: 'workshop_host'

    click_on 'Save'

    within '#host' do
      expect(page).to have_content sponsor.name
    end
  end

  scenario 'assigning a sponsor to a workshop' do
    workshop = Fabricate(:workshop_no_sponsor)
    visit edit_admin_workshop_path(workshop)

    select sponsor.name, from: 'workshop_sponsor_ids'

    click_on 'Save'

    within '#sponsors' do
      expect(page).to have_content sponsor.name
    end
  end

  scenario 'sending invitations to workshop attendees' do
    workshop = Fabricate(:workshop)
    visit admin_workshop_send_invites_path(workshop)
    click_on 'Students'

    expect(page).to have_content('Invitations to students are being emailed out')
  end

  scenario 'rendering a text file with all the workshop attendee emails' do
    workshop = Fabricate(:workshop)
    attendees = Fabricate.times(4, :attending_workshop_invitation, workshop: workshop)
    attendees_emails = attendees.map(&:member).map(&:email)
    visit admin_workshop_attendees_emails_path(workshop, format: :text)

    attendees_emails.each do |email|
      expect(page).to have_content(email)
    end
  end

  scenario 'rendering a list with the workshop attendee names' do
    workshop = Fabricate(:workshop)
    attendees = Fabricate.times(4, :attending_workshop_invitation, workshop: workshop)
    visit admin_workshop_attendees_checklist_path(workshop, format: :text)
    attendees.map(&:member).map(&:full_name).each do |name|
      expect(page).to have_content(name)
    end
  end

  scenario 'attempting to render a list with the workshop attendee names without a request text format' do
    workshop = Fabricate(:workshop)
    visit admin_workshop_attendees_checklist_path(workshop)

    expect(page.current_path).to eq(admin_workshop_path(workshop))
  end
end
