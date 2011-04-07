class Destinations
  attr_accessor :cities, :num

  def initialize(num)
    self.num = num
    self.cities = ('a'..'z').to_a[0,num]
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


class TravellingSalesBee < Bee
  def calculate_quality(m)
    workspace = hive.workspace
    m.each_cons(2).reduce(0) do |t, (a, b)|
      t + workspace.distance(a, b)
    end
  end

  def generate_random_matrix
    hive.workspace.random
  end

  def mutate_data(m)
    m = m.clone
    a = rand(m.length)
    b = a == m.length - 1 ? 0 : a + 1
    m[a], m[b] = m[b], m[a]
    m
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

  def work!
    case status
    when :active
      active!
    when :scout
      scout!
    when :inactive
      inactive!
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

  def scout!
    path = generate_random_matrix
    path_quality = calculate_quality(path)
    if path_quality < quality
      self.matrix = path
      dance!
    end
  end

  def active!
    neighbour = mutate_data matrix
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

  def inactive!
  end

  def calculate_quality(m)
    raise 'Implement Me'
  end

  def generate_random_matrix
    raise 'Implement Me'
  end

  def mutate_data
    raise 'Implement Me'
  end

  def to_s
    "Bee Status: #{ status } Quality: #{ quality } Visits: #{ num_visits }"
  end

  def inspect
    "#{to_s}\tMatrix: #{ matrix.join '->' }"
  end
end


class Hive
  ProbPersuasion = 0.70
  ProbMistake = 0.01

  attr_accessor :workspace

  attr_accessor :bees, :inactive_bees, :scouts
  attr_accessor :best, :quality, :initial_quality
  attr_accessor :history, :cycle

  attr_accessor :num_inactive, :num_active, :num_scout, :initial_scout, :initial_inactive
  attr_accessor :initial_max_visits, :initial_max_cycles
  attr_accessor :max_visits, :max_cycles

  def initialize(bee_type, workspace, num_inactive, num_active, num_scout, max_visits, max_cycles)
    self.workspace          = workspace
    self.num_active         = num_active
    self.initial_inactive   = self.num_inactive = num_inactive
    self.initial_scout      = self.num_scout    = num_scout
    self.initial_max_visits = self.max_visits   = max_visits
    self.initial_max_cycles = self.max_cycles   = max_cycles

    self.bees = []
    self.inactive_bees = []
    self.scouts = []
    self.history = []

    random_bee = bee_type.new(self, :active)
    self.best = random_bee.matrix.clone
    self.initial_quality = self.quality = random_bee.quality


    num_inactive.times do
      bee = bee_type.new(self, :inactive)
      bees << bee
      inactive_bees << bee
    end
    num_active.times do
      bees << bee_type.new(self, :active)
    end
    num_scout.times do
      bee = bee_type.new(self, :scout)
      bees << bee
      scouts << bee
    end
    bees.each { |bee| check_bee bee }
    self.history = [history.last]
  end

  def check_bee(bee)
    if quality > bee.quality
      history << [bee.status, cycle, num_scout.to_i, quality, best]
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
      self.cycle = n
      bees.each do |bee|
        bee.work!
      end
      self.num_scout = reallocate(num_scout, initial_scout, scouts)
      #self.num_inactive = reallocate(num_inactive, initial_inactive, inactive_bees)
      print '*' if n % increment == 0
    end
    puts
  end

  def reallocate(num, initial, group)
    last5 = history[-10..-1]
    if last5 and last5.all? { |a| a.first == :active }
      improvement = 0.001
    else
      improvement = quality / initial_quality.to_f
    end
    if num > initial * improvement
      num = initial * improvement
      while group.length > num
        break if group.length == 1
        bee = group.pop
        bee.status = :active
      end
    end
    num
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

  def inspect
    "HIVE STATUS -- Best Quality: #{ quality }\n     Best Matrix: #{ best.join('->') }\n#{ history.map(&:inspect).join("\n") }"
  end
end



def reload!
  load __FILE__
end

def run
  num_inactive = 20
  num_active = 10
  num_scout = 70
  max_visits = 100
  max_cycles = 2500

  hive = Hive.new TravellingSalesBee, Destinations.new(20), num_inactive, num_active, num_scout, max_visits, max_cycles

  puts 'initial random hive:'
  puts hive.inspect
  hive.solve
  hive
end
