State = Struct.new(:fips_int, :code, :abbreviation, :name) do
  def to_json(*a)
    JSON.generate({
      fipsInt: fips_int,
      code: code,
      abbreviation: abbreviation,
      name: name
    }, *a)
  end

  def is_actual_state?; fips_int < 60 && fips_int > 0; end

  def self.all
    @all ||= [
      [ 1, 'AL', 'Ala.', 'Alabama' ],
      [ 2, 'AK', 'Alaska' ],
      [ 4, 'AZ', 'Ariz.', 'Arizona' ],
      [ 5, 'AR', 'Ark.', 'Arkansas' ],
      [ 6, 'CA', 'Calif.', 'California' ],
      [ 8, 'CO', 'Colo.', 'Colorado' ],
      [ 9, 'CT', 'Conn.', 'Connecticut' ],
      [ 10, 'DE', 'Del.', 'Delaware' ],
      [ 11, 'DC', 'D.C.', 'District of Columbia' ],
      [ 12, 'FL', 'Fla.', 'Florida' ],
      [ 13, 'GA', 'Ga.', 'Georgia' ],
      [ 15, 'HI', 'Hawaii' ],
      [ 16, 'ID', 'Idaho' ],
      [ 17, 'IL', 'Ill.', 'Illinois' ],
      [ 18, 'IN', 'Ind.', 'Indiana' ],
      [ 19, 'IA', 'Iowa' ],
      [ 20, 'KS', 'Kan.', 'Kansas' ],
      [ 21, 'KY', 'Ky.', 'Kentucky' ],
      [ 22, 'LA', 'La.', 'Louisiana' ],
      [ 23, 'ME', 'Maine' ],
      [ 24, 'MD', 'Md.', 'Maryland' ],
      [ 25, 'MA', 'Mass.', 'Massachusetts' ],
      [ 26, 'MI', 'Mich.', 'Michigan' ],
      [ 27, 'MN', 'Minn.', 'Minnesota' ],
      [ 28, 'MS', 'Miss.', 'Mississippi' ],
      [ 29, 'MO', 'Mo.', 'Missouri' ],
      [ 30, 'MT', 'Mont.', 'Montana' ],
      [ 31, 'NE', 'Neb.', 'Nebraska' ],
      [ 32, 'NV', 'Nev.', 'Nevada' ],
      [ 33, 'NH', 'N.H.', 'New Hampshire' ],
      [ 34, 'NJ', 'N.J.', 'New Jersey' ],
      [ 35, 'NM', 'N.M.', 'New Mexico' ],
      [ 36, 'NY', 'N.Y.', 'New York' ],
      [ 37, 'NC', 'N.C.', 'North Carolina' ],
      [ 38, 'ND', 'N.D.', 'North Dakota' ],
      [ 39, 'OH', 'Ohio' ],
      [ 40, 'OK', 'Okla.', 'Oklahoma' ],
      [ 41, 'OR', 'Ore.', 'Oregon' ],
      [ 42, 'PA', 'Pa.', 'Pennsylvania' ],
      [ 44, 'RI', 'R.I.', 'Rhode Island' ],
      [ 45, 'SC', 'S.C.', 'South Carolina' ],
      [ 46, 'SD', 'S.D.', 'South Dakota' ],
      [ 47, 'TN', 'Tenn.', 'Tennessee' ],
      [ 48, 'TX', 'Texas' ],
      [ 49, 'UT', 'Utah' ],
      [ 50, 'VT', 'Vt.', 'Vermont' ],
      [ 51, 'VA', 'Va.', 'Virginia' ],
      [ 53, 'WA', 'Wash.', 'Washington' ],
      [ 54, 'WV', 'W.Va.', 'West Virginia' ],
      [ 55, 'WI', 'Wis.', 'Wisconsin' ],
      [ 56, 'WY', 'Wyo.', 'Wyoming' ],
      [ 60, 'AS', 'American Samoa' ],
      [ 66, 'GU', 'Guam' ],
      [ 69, 'MP', 'Northern Mariana Islands' ],
      [ 72, 'PR', 'P.R.', 'Puerto Rico' ],
      [ 78, 'VI', 'V.I.', 'Virgin Islands' ],
      [ -1, 'abroad', 'abroad', 'Democrats Abroad' ]
    ].map { |arr| State.new(arr[0], arr[1], arr[2], arr[3] || arr[2]) }
  end

  def self.find_by_code(code)
    @by_code ||= State.all.map{ |s| [ s.code, s ] }.to_h
    @by_code.fetch(code.to_s)
  end

  def self.find_by_fips_int(fips_int)
    @by_fips_int ||= State.all.map { |s| [ s.fips_int, s ] }.to_h
    @by_fips_int.fetch(fips_int.to_i)
  end
end
