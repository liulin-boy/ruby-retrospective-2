class Collection
  include Enumerable

  attr_reader :songs, :names, :artists, :albums

  def initialize(songs)
    @names   = songs.map { |song| song.name   }.uniq
    @artists = songs.map { |song| song.artist }.uniq
    @albums  = songs.map { |song| song.album  }.uniq
    @songs   = songs
  end

  def each
    @songs.map { |song| yield song }
  end

  def self.parse(text)
    sliced_array = text.split("\n").select { |line| !line.empty? }.each_slice(3)
    songs = sliced_array.map { |song| Song.new(song[0], song[1], song[2]) }
    Collection.new(songs)
  end

  def filter(criteria = Criteria.new { true })
    new_subset = @songs.select { |song| song.match? criteria }
    Collection.new(new_subset)
  end

  def adjoin(other_subset)
    Collection.new(@songs.to_a | other_subset.to_a)
  end

  def to_s
    @songs.map { |song| song.inspect }.each_slice(1) { |a| puts a.join("\n")}
  end
end

class Song
  attr_reader :name, :artist, :album

  def initialize(name, artist, album)
    @name, @artist, @album = name, artist, album
  end

  def match?(criteria)
    criteria.call(self)
  end

  def to_s
    "%-25s %-25s %-26s" % [@name, @artist, @album]
  end
end


class Criteria
  def initialize(criteria = Proc.new)
    @criteria = criteria
  end

  def call(params)
    @criteria.call(params)
  end

  def self.name(name)
    Criteria.new { |song| song.name == name }
  end

  def self.artist(artist)
    Criteria.new { |song| song.artist == artist }
  end

  def self.album(album)
    Criteria.new { |song| song.album == album }
  end

  def &(other)
    Criteria.new { |song| song.match?(self) && song.match?(other) }
  end

  def |(other)
    Criteria.new { |song| song.match?(self) || song.match?(other) }
  end

  def !
    Criteria.new { |song| !song.match?(self) }
  end
end