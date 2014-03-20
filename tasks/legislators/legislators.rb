require 'spreadsheet'

class Legislators

  # options:
  #   cache: don't re-download unitedstates data
  #   current: limit to current legislators only
  #   limit: stop after N legislators
  #   clear: wipe the db of legislators first
  #   bioguide_id: limit to one legislator, with this bioguide ID

  def self.run(options = {})

    # 1. Download the excel file
    # 2. Compute checksum and exit if it's same as the last download
    # 3. If not, update the db

    mpbook_url  = "http://www.prsindia.org/MPTrack-15.xls"
    mpbook_path = "data/lsbook_new.xlx"

    result = Utils.curl mpbook_url, mpbook_path
    if (not result)
     Report.failure self, "Couldn't download the MP file"
    end

    #TODO: compute checksum and compare with the checksum of the previous download

    bad_legislators = []
    count = 0

    book = Spreadsheet.open mpbook_path
    sheet1 = book.worksheet 0 # Access the first worksheet
    is_first = true
    sheet1.each do |row|

      if (is_first)
        is_first = false
        next
      end

      attributes_new = attributes_from_prs row
      legislator = Legislator.find_or_initialize_by bioguide_id: attributes_new[:bioguide_id]
      legislator.attributes = attributes_new

      if legislator.save
        count += 1
      else
        bad_legislators << {attributes: legislator.attributes, errors: legislator.errors.full_messages}
      end
    end

    if bad_legislators.any?
      Report.warning self, "Failed to save #{bad_legislators.size} PRS LS legislators.", bad_legislators: bad_legislators
    end

    Report.success self, "Processed #{count} legislators from PRS"
  end

  def self.attributes_from_prs(row)
    name_index = 0
    elected_index = 1
    term_start_index = 2
    term_end_index = 3
    state_name_index = 4
    constituency_index = 5
    party_index = 6
    gender_index = 7
    education_qualification_index = 8
    education_details_index = 9
    age_index = 10
    debates_index = 11
    private_bills_index = 12
    questions_index = 13
    attendance_index = 14
    notes_index = 15

    first_name, last_name = Utils.split_fullname row[name_index]
    elected = row[elected_index].downcase.eql? 'Elected'.downcase

    attributes = {
      bioguide_id: row[name_index] + '_' + row[state_name_index],
      first_name: first_name,
      last_name: last_name,
      gender: row[gender_index],
      age: row[age_index].to_s,
      state: row[state_name_index],
      party: row[party_index],
      elected: elected,
      education_qualification: row[education_qualification_index],
      education_details: row[education_details_index],
      debates: row[debates_index],
      private_bills: row[private_bills_index],
      questions: row[questions_index],
      attendance: row[attendance_index],
      notes: row[notes_index],
      chamber: "Lok Sabha", #TODO: use ruby symbols?
      term_start: row[term_start_index].to_s,
      term_end: row[term_end_index].to_s
    }

    attributes # return attributes
  end

  def self.social_media_from(details)
    facebook = details['social']['facebook_id'] || details['social']['facebook']
    facebook = facebook.to_s if facebook
    {
      twitter_id: details['social']['twitter'],
      youtube_id: details['social']['youtube'],
      facebook_id: facebook
    }
  end

end
