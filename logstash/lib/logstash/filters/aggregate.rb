# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "logstash/environment"
require "set"

class LogStash::Filters::Aggregate < LogStash::Filters::Base

	config_name "aggregate"
	milestone 3

	# The regular expression to match.
	config :start_pattern, :validate => :string, :default => ""
	config :pattern, :validate => :string, :default => "X_X_X_X_X_X_X_X12312dasX_"
	config :end_pattern, :validate => :string, :default => ""

	# Which part of the pattern contains the identity that join them together
	config :identity, :validate => :string, :default => "id"

	config :overwrite, :validate => :array, :default => []

	# Logstash ships by default with a bunch of patterns, so you don't
	# necessarily need to define this yourself unless you are adding additional
	# patterns.
	#
	# Pattern files are plain text with format:
	#
	#     NAME PATTERN
	#
	# For example:
	#
	#     NUMBER \d+
	config :patterns_dir, :validate => :array, :default => []

	# for debugging & testing purposes, do not use in production. allows periodic flushing of pending events
	config :enable_flush, :validate => :boolean, :default => false

	# Detect if we are running from a jarfile, pick the right path.
	@@patterns_path = Set.new
	@@patterns_path += [LogStash::Environment.pattern_path("*")]

	public
	def initialize(params)
		super(params)

		@threadsafe = false

		# This filter needs to keep state.
		@pending = Hash.new { |hash, key| hash[key] = [1, nil] } # first element is the index of the hash bucket
		# a cache of capture name handler methods.
		@handlers = {}
	end

	public
	def register
		require "grok-pure" # rubygem 'jls-grok'

		@grok_start = Grok::Pile.new
		@grok_middle = Grok::Pile.new
		@grok_end = Grok::Pile.new

		@patterns_dir = @@patterns_path.to_a + @patterns_dir
		@patterns_dir.each do |path|
			if File.directory?(path)
				path = File.join(path, "*")
			end

			Dir.glob(path).each do |file|
				@logger.info("Grok loading patterns from file", :path => file)
				@grok_start.add_patterns_from_file(file)
				@grok_middle.add_patterns_from_file(file)
				@grok_end.add_patterns_from_file(file)
			end
		end

		@grok_start.compile(@start_pattern)
		@grok_middle.compile(@pattern)
		@grok_end.compile(@end_pattern)

		@logger.debug("Registered aggregate plugin", :type => @type, :config => @config)
	end # def register

	private
	def handle_match(match, event)
		match.each_capture do |capture, value|
			handle(capture, value, event)
		end
	end

	private
	def collapse_event!(event)
		event["message"] = event["message"].join("\n") if event["message"].is_a?(Array)
		event["@timestamp"] = event["@timestamp"].first if event["@timestamp"].is_a?(Array)
		event
	end

	public
	def filter(event)
		return unless filter?(event)

		if event["message"].is_a?(Array)
			message = event["message"].first
		else
			message = event["message"]
		end

		grok, start_match = @grok_start.match(message)
		grok, middle_match = @grok_middle.match(message)
		grok, end_match = @grok_end.match(message)

		match = start_match || middle_match || end_match

		# id = ?
		id = match.captures["INT:id"].first
		# need to extract the ID before handling the capture, or else we will include 
		# the wrong message in the event
		if start_match
			index = @pending[id][0]
			@pending[id][index] = event
			handle_match(start_match, event)
			event.tag "aggregate"
			event.cancel
		end

		if middle_match
			index = @pending[id][0]
			@pending[id][index].append(event)
			event.cancel
		end

		if end_match
			index = @pending[id][0]
			@pending[id][index].append(event)
			@pending[id][0] += 1
		end

		@logger.debug("Aggregate", :pattern => @pattern, :message => event["message"],
					  :match => match, :negate => @negate)

		if !event.cancelled?
			collapse_event!(event)
			filter_matched(event) if start_match || middle_match || end_match
		end
	end # def filter

	private
	def handle(capture, value, event)
		handler = @handlers[capture] ||= compile_capture_handler(capture)
		return handler.call(value, event)
	end

	private
	def compile_capture_handler(capture)
		# SYNTAX:SEMANTIC:TYPE
		syntax, semantic, coerce = capture.split(":")

		# each_capture do |fullname, value|
		#   capture_handlers[fullname].call(value, event)
		# end

		code = []
		code << "# for capture #{capture}"
		code << "lambda do |value, event|"
		#code << "  p :value => value, :event => event"
		if semantic.nil?
			if @named_captures_only
				# Abort early if we are only keeping named (semantic) captures
				# and this capture has no semantic name.
				code << "  return"
			else
				field = syntax
			end
		else
			field = semantic
		end
		code << "  return if value.nil? || value.empty?" unless @keep_empty_captures
		if coerce
			case coerce
			when "int"; code << "  value = value.to_i"
			when "float"; code << "  value = value.to_f"
			end
		end

		code << "  # field: #{field}"
		if @overwrite.include?(field)
			code << "  event[field] = value"
		else
			code << "  v = event[field]"
			code << "  if v.nil?"
			code << "    event[field] = value"
			code << "  elsif v.is_a?(Array)"
			code << "    event[field] << value"
			code << "  elsif v.is_a?(String)"
			# Promote to array since we aren't overwriting.
			code << "    event[field] = [v, value]"
			code << "  end"
		end
		code << "  return"
		code << "end"

		#puts code
		return eval(code.join("\n"), binding, "<grok capture #{capture}>")
	end # def compile_capture_handler

	# Flush any pending messages. This is generally used for unit testing only.
	#
	# Note: flush is disabled now; it is preferable to use the multiline codec.
	public
	def flush
		return [] unless @enable_flush

		events = []
		@pending.each do |key, value|
			value.each_index do |i|
				next if i == 0
				event = value[i]
				event.uncancel
				events << collapse_event!(event)
			end	
		end
		@pending.clear
		return events
	end # def flush

	private

	def collapse_event!(event)
		event["message"] = event["message"].join("\n") if event["message"].is_a?(Array)
		event["@timestamp"] = event["@timestamp"].first if event["@timestamp"].is_a?(Array)
		event
	end
end # class LogStash::Filters::Multiline
