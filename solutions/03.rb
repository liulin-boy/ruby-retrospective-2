class Expr
  def self.build(expr_tree)
    case expr_tree.first
      when :number   then Number.new       expr_tree[1]
      when :variable then Variable.new     expr_tree[1]
      when :-        then -          build(expr_tree[1])
      when :sin      then Sine.new   build(expr_tree[1])
      when :cos      then Cosine.new build(expr_tree[1])
      when :+        then build(expr_tree[1]) + (build expr_tree[2])
      when :*        then build(expr_tree[1]) * (build expr_tree[2])
    end
  end

  def +(other)
    Addition.new self, other
  end

  def *(other)
    Multiplication.new self, other
  end

  def -@
    Negation.new self
  end

  def derive(var)
    derivative(var).simplify
  end
end

class Unary < Expr
  attr_reader :operand

  def initialize(operand)
    @operand = operand
  end

  def ==(other)
    self.class == other.class and self.operand == other.operand
  end

  def exact?
    operand.exact?
  end

  def simplify
    self
  end
end

class Number < Unary
  def evaluate(env = {})
    operand
  end

  def self.zero
    Number.new(0)
  end

  def self.one
    Number.new(1)
  end

  def derivative(varible)
    Number.zero
  end

  def exact?
    true
  end

  def to_s
    operand.to_s
  end
end

class Variable < Unary
  def evaluate(env = {})
    env.fetch operand
  end

  def derivative(var)
    var == @operand ? Number.one : Number.zero
  end

  def exact?
    false
  end

  def to_s
    operand.to_s
  end
end

class Negation < Unary
  def evaluate(env = {})
    -operand.evaluate(env)
  end

  def simplify
    if exact?
      Number.new(-operand.simplify.evaluate)
    else
      Negation.new(operand.simplify)
    end
  end

  def derivative(var)
    Negation.new operand.derivative(var)
  end

  def exact?
    operand.exact?
  end

  def to_s
    "-#{operand}"
  end
end

class Sine < Unary
  def evaluate(env = {})
    Math.sin operand.evaluate(env)
  end

  def simplify
    if exact?
      Number.new Math.sin(operand.simplify.evaluate)
    else
      Sine.new operand.simplify
    end
  end

  def derivative(var)
    operand.derivative(var) * Cosine.new(operand)
  end

  def to_s
    "sin(#{operand})"
  end
end

class Cosine < Unary
  def evaluate(env = {})
    Math.cos operand.evaluate(env)
  end

  def simplify
    if exact?
      Number.new Math.cos(operand.simplify.evaluate)
    else
      Cosine.new operand.simplify
    end
  end

  def derivative(var)
    operand.derivative(var) * -Sine.new(operand)
  end

  def to_s
    "cos(#{operand})"
  end
end

class Binary < Expr
  attr_reader :left_operand, :right_operand

  def initialize(left_operand, right_operand)
    @left_operand  = left_operand
    @right_operand = right_operand
  end

  def ==(other)
    self.class == other.class and
      self.left_operand == other.left_operand and
      self.right_operand == other.right_operand
  end

  def simplify
    self.class.new left_operand.simplify, right_operand.simplify
  end

  def exact?
    left_operand.simplify.exact? and right_operand.simplify.exact?
  end
end

class Addition < Binary
  def evaluate(env = {})
    left_operand.evaluate(env) + right_operand.evaluate(env)
  end

 def simplify
    if exact? then Number.new(left_operand.simplify.evaluate + right_operand.simplify.evaluate)
    elsif left_operand  == Number.zero then right_operand.simplify
    elsif right_operand == Number.zero then left_operand.simplify
    else super
    end
  end

  def derivative(var)
    left_operand.derivative(var) + right_operand.derivative(var)
  end

  def to_s
    "(#{left_operand} + #{right_operand})"
  end
end

class Multiplication < Binary
  def evaluate(env = {})
    left_operand.evaluate(env) * right_operand.evaluate(env)
  end

  def simplify
    if exact? then Number.new(left_operand.simplify.evaluate * right_operand.simplify.evaluate)
    elsif left_operand  == Number.zero then Number.zero
    elsif right_operand == Number.zero then Number.zero
    elsif left_operand  == Number.one  then right_operand.simplify
    elsif right_operand == Number.one  then left_operand.simplify
    else super
    end
  end

  def derivative(var)
    left_operand.derivative(var) * right_operand + left_operand * right_operand.derivative(var)
  end

  def to_s
    "(#{left_operand} * #{right_operand})"
  end
end

