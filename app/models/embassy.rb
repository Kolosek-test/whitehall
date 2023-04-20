class Embassy
  def initialize(world_location)
    @world_location = world_location
  end

  delegate :name, to: :@world_location

  def offices
    @world_location.worldwide_organisations.map(&:embassy_offices).flatten
  end

  def consular_services_organisations
    @world_location.worldwide_organisations.select do |org|
      org.embassy_offices.any?
    end
  end

  def remote_services_country
    return nil if offices_in_location.any?

    offices = consular_services_organisations.map(&:offices).flatten
    countries = offices.map(&:country)
    unless countries.empty?
      countries.first
    end
  end

  RemoteOffice = Struct.new(:name, :location, :path, keyword_init: true)

  def remote_office
    if special_case?
      RemoteOffice.new(name: SPECIAL_CASES[name][:building],
                       location: SPECIAL_CASES[name][:location],
                       path: SPECIAL_CASES[name][:base_path])
    elsif can_assist_in_other_location?
      RemoteOffice.new(name: organisation.name,
                       location: remote_services_country,
                       path: organisation.public_path)
    end
  end

  def can_assist_in_location?
    return false if special_case?
    return false if can_assist_in_other_location?

    offices_in_location.any? || offices_in_unknown_location.any?
  end

  def can_assist_british_nationals?
    special_case? || offices.any?
  end

private

  def can_assist_in_other_location?
    remote_services_country.present?
  end

  def offices_in_location
    offices.select { |office| office.country == @world_location }
  end

  def offices_in_unknown_location
    offices.select { |office| office.country.nil? }
  end

  def organisation
    consular_services_organisations.first
  end

  def special_case?
    SPECIAL_CASES.key?(name)
  end

  SPECIAL_CASES = {
    "Central African Republic" => {
      building: "Foreign, Commonwealth and Development Office",
      location: "the UK",
      base_path: "/government/organisations/foreign-commonwealth-development-office",
    },
    "French Polynesia" => {
      building: "British High Commission Wellington",
      location: "New Zealand",
      base_path: "/government/world/organisations/british-high-commission-wellington",
    },
    "Holy See" => {
      building: "British Embassy Rome",
      location: "Italy",
      base_path: "/government/world/organisations/british-embassy-rome",
    },
    "Libya" => {
      building: "British Embassy Tunis",
      location: "Tunisia",
      base_path: "/government/world/organisations/british-embassy-tunis",
    },
    "Liechtenstein" => {
      building: "British Embassy Berne",
      location: "Switzerland",
      base_path: "/government/world/organisations/british-embassy-berne",
    },
    "Macao" => {
      building: "British Consulate General Hong Kong",
      location: "Hong Kong",
      base_path: "/government/world/organisations/british-consulate-general-hong-kong",
    },
    "Marshall Islands" => {
      building: "British High Commission Suva",
      location: "Fiji",
      base_path: "/government/world/organisations/british-high-commission-suva",
    },
    "Micronesia" => {
      building: "British High Commission Suva",
      location: "Fiji",
      base_path: "/government/world/organisations/british-high-commission-suva",
    },
    "New Caledonia" => {
      building: "British High Commission Wellington",
      location: "New Zealand",
      base_path: "/government/world/organisations/british-high-commission-wellington",
    },
    "St Martin" => {
      building: "British Embassy Paris",
      location: "France",
      base_path: "/government/world/organisations/british-embassy-paris",
    },
    "Syria" => {
      building: "British Embassy Beirut",
      location: "Lebanon",
      base_path: "/government/world/organisations/british-embassy-beirut",
    },
    "Timor Leste" => {
      building: "British Embassy Jakarta",
      location: "Indonesia",
      base_path: "/government/world/organisations/british-embassy-jakarta",
    },
  }.freeze
end
