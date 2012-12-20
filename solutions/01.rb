class Integer
  def prime_divisors
    2.upto(abs).select do |n|
      2.upto(n.pred).none? { |d| n.remainder(d).zero? } and remainder(n).zero?
    end
  end
end

class Range
	def fizzbuzz
    map do |n|
      if    n % 15 == 0 then :fizzbuzz
      elsif n % 3  == 0 then :fizz
      elsif n % 5  == 0 then :buzz
      else n
      end
    end
  end
end

class Hash
  def group_values
    keys.group_by { |key| self[key] }
  end
end

class Array
  def densities
    map { |elem| count elem }
  end
end
