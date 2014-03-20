class Legislator
  include Api::Model
  publicly :queryable

  basic_fields  :bioguide_id, :first_name, :last_name, :gender,
      :age, :elected, :education_qualification, :education_details,
      :debates, :private_bills, :questions, :attendance, :notes,
      :state, :party, :chamber, :constituency, :phone, :fax,
      :office, :website, :twitter_id, :facebook_id,
      :youtube_id, :term_start, :term_end

  search_fields :first_name, :last_name, :constituency, :state

  include Mongoid::Document
  include Mongoid::Timestamps

  #In the absence of any suitable id, we'd just use the concatenation
  #of the first_name, last_name, and the state as the id. Likely, we
  #won't hit more than one such legislator?
  index bioguide_id: 1

  index chamber: 1
  index state: 1
  index constituency: 1
  index party: 1
  index gender: 1
  index education_qualification: 1

  index first_name: 1
  index last_name: 1

  index term_start: 1
  index term_end: 1
  index terms_count: 1 # undocumented for now
end
