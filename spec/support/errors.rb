# frozen_string_literal: true

TestError = Class.new(StandardError)
ParentError = Class.new(TestError)
ChildError = Class.new(ParentError)
UnexpectedError = Class.new(StandardError)
