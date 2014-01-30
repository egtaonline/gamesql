class Command
  def initialize(file_location)
    @file_location = file_location
  end
  
  def exec(database='gamesql')
    `psql -d #{database} -f #{@file_location}`
  end
end