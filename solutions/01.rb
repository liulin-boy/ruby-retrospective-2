class Integer
  def prime_divisors
    def prime?
      return false if self < 2
   	  (2..(self / 2)).each do |i|
	    return false if self.remainder(i) == 0
	  end
	  true
	end
   return (-self).prime_divisors if self < 0
   (1..self).select { |n| n.prime? and self.remainder(n) == 0 }
  end
end

class Range
	def fizzbuzz
	  map do |n|
	    if n.remainder(3) == 0
		  n.remainder(5) == 0 ? :fizzbuzz : :fizz
        else
         n.remainder(5) == 0 ? :buzz : n
        end
      end
	end
end

class Hash
  def group_values
    v = values.uniq.map do |val|
	  [val, keys.select { |key| self[key] == val } ]
    end
	Hash[v]
  end
end

class Array
  def densities
    map { |elem| select { |x| x == elem }.size }
  end
end