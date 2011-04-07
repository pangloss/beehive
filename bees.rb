class Destinations
  attr_accessor :cities, :num

  def initialize(num)
    self.num = num
    self.cities = ('A'..'Z').to_a[0,num]
  end

  def distance(a, b)
    a, b = "#{a}#{b}".each_byte.to_a
    if a < b
      1.0 * b - a
    else
      1.5 * a - b
    end
  end

  def shortest_path_length
    num - 1
  end

  def random
    cities.sample(num)
  end

  def to_s
    "Cities: #{ cities.join ' ' }"
  end
end


class Bee
  attr_accessor :hive, :status, :matrix, :quality, :num_visits

  def initialize(hive, status)
    self.hive = hive
    self.status = status
    self.matrix = generate_random_matrix
  end

  def matrix=(m)
    @matrix = m
    self.quality = calculate_quality(m)
    self.num_visits = 0
    m
  end

  def num_visits=(n)
    @num_visits = n
    over_visit_limit! if n > hive.max_visits
    n
  end

  def generate_random_matrix
    hive.cities.random
  end

  def calculate_quality(m)
    cities = hive.cities
    m.each_cons(2).reduce(0) do |t, (a, b)|
      t + cities.distance(a, b)
    end
  end

  def generate_neighbour_matrix(m)
    m = m.clone
    a = rand(m.length)
    b = a == m.length - 1 ? 0 : a + 1
    m[a], m[b] = m[b], m[a]
    m
  end

  def work!
    case status
    when :active
      bee_active!
    when :scout
      bumble!
    when :inactive
      bee_lazy
    end
  end

  def bumble!
    path = generate_random_matrix
    path_quality = calculate_quality(path)
    if path_quality < quality
      self.matrix = path
      dance!
    end
  end

  def bee_lazy
  end

  def bee_active!
    neighbour = generate_neighbour_matrix matrix
    neighbour_quality = calculate_quality(neighbour)
    prob = rand
    if neighbour_quality < quality
      if prob < Hive::ProbMistake
        self.num_visits += 1
      else
        self.matrix = neighbour
        dance!
      end
    else
      if prob < Hive::ProbMistake
        self.matrix = neighbour
        dance!
      else
        self.num_visits += 1
      end
    end
  end

  def over_visit_limit!
    self.status = :inactive
    self.num_visits = 0
    hive.went_inactive self
  end

  def dance!
    hive.check_bee self
    hive.waggle!(self)
  end

  def to_s
    "Bee Status: #{ status } Quality: #{ quality } Visits: #{ num_visits }"
  end

  def inspect
    "#{to_s}\tMatrix: #{ matrix.join '->' }"
  end
end


class Hive
  ProbPersuasion = 0.90
  ProbMistake = 0.01

  attr_accessor :cities

  attr_accessor :bees, :inactive_bees
  attr_accessor :best, :quality

  attr_accessor :num_inactive, :num_active, :num_scout
  attr_accessor :max_visits, :max_cycles

  def inspect
    "HIVE STATUS -- Best Quality: #{ quality }\n     Best Matrix: #{ best.join('->') }"
  end

  def initialize(num_inactive, num_active, num_scout, max_visits, max_cycles, cities)
    self.cities = cities
    self.num_inactive  = num_inactive
    self.num_active    = num_active
    self.num_scout     = num_scout
    self.max_visits = max_visits
    self.max_cycles = max_cycles

    self.inactive_bees = []
    self.bees = []
    self.inactive_bees = []

    random_bee = Bee.new(self, :active)
    self.best = random_bee.matrix.clone
    self.quality = random_bee.quality

    num_inactive.times do
      bee = Bee.new(self, :inactive)
      bees << bee
      inactive_bees << bee
    end
    num_active.times do
      bees << Bee.new(self, :active)
    end
    num_scout.times do
      bees << Bee.new(self, :scout)
    end
    bees.each { |bee| check_bee bee }
  end

  def check_bee(bee)
    if quality > bee.quality
      self.best = bee.matrix.clone
      self.quality = bee.quality
    end
  end

  def num_bees
    num_inactive + num_active + num_scout
  end

  def solve
    puts  "Flying around...\n"
    puts  "Progress: |#{ '=' * 10 }|"
    print "           "
    increment = max_cycles / 10
    max_cycles.times do |n|
      bees.each do |bee|
        bee.work!
      end
      if n % increment == 0
        print '*'
      end
    end
    puts
  end

  def went_inactive(bee)
    x = rand(num_inactive)
    inactive_bees[x].status = :active
    inactive_bees[x] = bee
  end

  def waggle!(instructor)
    inactive_bees.each do |student|
      if instructor.quality < student.quality and Hive::ProbPersuasion > rand
        student.matrix = instructor.matrix
      end
    end
  end
end

def reload!
  load __FILE__
end

def run
  num_inactive = 20
  num_active = 50
  num_scout = 30
  max_visits = 100
  max_cycles = 1500

  cities = Destinations.new 20

  hive = Hive.new num_inactive, num_active, num_scout, max_visits, max_cycles, cities

  puts 'initial random hive:'
  puts hive
  hive.solve
  hive
end
