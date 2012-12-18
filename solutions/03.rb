class Expr
  attr_reader :expression

  def initialize(expression_tree)
    if expression_tree.length == 2
      @expression = Unary.new(expression_tree)
    else
      @expression = Binary.new(expression_tree)
    end
  end

  def self.build(expression_tree)
    Expr.new(expression_tree)
  end

  def ==(other)
    to_array == other.to_array
  end

  def method_missing(name, *args, &block)
    @expression.send(name, *args, &block)
  end

  def to_array
    @expression.expression.expression
  end

  def inspect
    to_array
  end
end

class Unary < Expr
  def initialize(expression_tree)
    case expression_tree[0]
      when :number   then @expression = Number.new  (expression_tree)
      when :variable then @expression = Variable.new(expression_tree)
      when :-        then @expression = Negation.new(expression_tree)
      when :sin      then @expression = Sine.new    (expression_tree)
      when :cos      then @expression = Cosine.new  (expression_tree)
    end
  end

  def argument
    @expression[1]
  end
end

class Number < Unary
  def initialize(expression_tree)
    @expression = expression_tree
  end

  def exact?
    true
  end

  def simplify
    Expr.new(@expression)
  end

  def evaluate(scope = {})
    argument
  end

  def derive(variable)
    Expr.new([:number, 0])
  end
end

class Variable < Unary
  def initialize(expression_tree)
    @expression = expression_tree
  end

  def evaluate(scope = {})
    scope[argument]
  end

  def exact?
    false
  end

  def simplify
    Expr.new([:variable, argument])
  end

  def derive(variable)
    variable == argument ? Expr.new([:number, 1]) : Expr.new([:number, 0])
  end
end

class Negation < Unary
  def initialize(expression_tree)
    @expression = expression_tree
  end

  def evaluate(scope = {})
    -Expr.new(argument).evaluate(scope)
  end

  def exact?
    Expr.new(argument).exact?
  end

  def simplify
    if exact?
      Expr.new([:number, evaluate])
    else
      Expr.new([:-, Expr.new(argument).simplify.to_array])
    end
  end

  def derive(variable)
    new_argument = Expr.new(argument).derive(variable).to_array
    Expr.new([:-, new_argument]).simplify
  end
end

class Sine < Unary
  def initialize(expression_tree)
    @expression = expression_tree
  end

  def evaluate(scope = {})
    Math.sin Expr.new(argument).evaluate(scope)
  end

  def exact?
    Expr.new(argument).exact?
  end

  def simplify
    if exact?
      Expr.new [:number, evaluate]
    else
      Expr.new([:sin, Expr.new(argument).simplify.to_array])
    end
  end

  def derive(variable)
    inner_derivative = Expr.new(argument).derive(variable).to_array
    Expr.new([:*, inner_derivative, [:cos, argument]]).simplify
  end
end

class Cosine < Unary
  def initialize(expression_tree)
    @expression = expression_tree
  end

  def evaluate(scope = {})
    Math.cos Expr.new(argument).evaluate(scope)
  end

  def exact?
    Expr.new(argument).exact?
  end

  def simplify
    if exact?
      Expr.new [:number, evaluate]
    else
      Expr.new([:cos, Expr.new(argument).simplify.to_array])
    end
  end

  def derive(variable)
    inner_derivative = Expr.new(argument).derive(variable).to_array
    Expr.new([:*, inner_derivative, [:-, [:sin, argument]]]).simplify
  end
end

class Binary < Expr
  def initialize(expression_tree)
    case expression_tree[0]
      when :+ then @expression = Addition.new      (expression_tree)
      when :* then @expression = Multiplication.new(expression_tree)
    end
  end

  def left_argument
    @expression[1]
  end

  def right_argument
    @expression[2]
  end
end

class Addition < Binary
  def initialize(expression_tree)
    @expression = expression_tree
  end

  def evaluate(scope = {})
    Expr.new(left_argument).evaluate(scope) + Expr.new(right_argument).evaluate(scope)
  end

  def exact?
    Expr.new(left_argument).exact? && Expr.new(right_argument).exact?
  end

  def simplify
    simplified_left = Expr.new(left_argument).simplify
    simplified_right = Expr.new(right_argument).simplify
    if exact?
      Expr.new([:number, evaluate])
    elsif simplified_left.exact? && simplified_left.evaluate == 0
      simplified_right
    elsif simplified_right.exact? && simplified_right.evaluate == 0
      simplified_left
    else
      Expr.new([:+, simplified_left.to_array, simplified_right.to_array])
    end
  end

  def derive(variable)
    derivative_of_left_argument = Expr.new(left_argument).derive(variable).to_array
    derivative_of_right_argument = Expr.new(right_argument).derive(variable).to_array
    Expr.new([:+, derivative_of_left_argument, derivative_of_right_argument]).simplify
  end
end

class Multiplication < Binary
  def initialize(expression_tree)
    @expression = expression_tree
  end

  def evaluate(scope = {})
    result = 0 if Expr.new(left_argument).exact? && Expr.new(left_argument).evaluate(scope) == 0
    result = 0 if Expr.new(right_argument).exact? && Expr.new(right_argument).evaluate(scope) == 0
    if result != 0
      Expr.new(left_argument).evaluate(scope) * Expr.new(right_argument).evaluate(scope)
    else
      result
    end
  end

  def exact?
    result = Expr.new(left_argument).exact? && Expr.new(right_argument).exact?
    result ||= Expr.new(left_argument).exact? && Expr.new(left_argument).evaluate == 0
    result ||= Expr.new(right_argument).exact? && Expr.new(right_argument).evaluate == 0
  end

  def simplify
    simplified_left = Expr.new(left_argument).simplify
    simplified_right = Expr.new(right_argument).simplify
    if exact?
      Expr.new([:number, evaluate])
    elsif simplified_left.exact? && simplified_left.evaluate == 1
      simplified_right
    elsif simplified_right.exact? && simplified_right.evaluate == 1
      simplified_left
    else
      Expr.new([:*, simplified_left.to_array, simplified_right.to_array])
    end
  end

  def derive(variable)
    left_derivative = Expr.new(left_argument).derive(variable)
    right_derivative = Expr.new(right_argument).derive(variable)
    new_left_argument = [:*, left_derivative.to_array, right_argument]
    new_right_argument = [:*, left_argument, right_derivative.to_array]
    Expr.new([:+, new_left_argument, new_right_argument]).simplify
  end
end