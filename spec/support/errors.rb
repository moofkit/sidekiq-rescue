# frozen_string_literal: true

class TestError < StandardError
end

class ParentError < TestError
end

class ChildError < ParentError
end

class UnexpectedError < StandardError
end
