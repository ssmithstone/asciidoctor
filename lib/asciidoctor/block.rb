module Asciidoctor
# Public: Methods for managing blocks of Asciidoc content in a section.
#
# Examples
#
#   block = Asciidoctor::Block.new(parent, :paragraph, :source => '_This_ is a <test>')
#   block.content
#   => "<em>This</em> is a &lt;test&gt;"
class Block < AbstractBlock

  # Public: Create alias for context to be consistent w/ AsciiDoc
  alias :blockname :context

  # Public: Get/Set the original Array content for this block, if applicable
  attr_accessor :lines

  # Public: Initialize an Asciidoctor::Block object.
  #
  # parent        - The parent AbstractBlock with a compound content model to which this Block will be appended.
  # context       - The Symbol context name for the type of content (e.g., :paragraph).
  # opts          - a Hash of options to customize block initialization: (default: {})
  #                 * :content_model indicates whether blocks can be nested in this Block (:compound), otherwise
  #                     how the lines should be processed (:simple, :verbatim, :raw, :empty). (default: :simple)
  #                 * :attributes a Hash of attributes (key/value pairs) to assign to this Block. (default: {})
  #                 * :source a String or Array of raw source for this Block. (default: nil)
  #--
  # QUESTION should we store source_data as lines for blocks that have compound content models?
  def initialize(parent, context, opts = {})
    super(parent, context)
    @content_model = opts[:content_model] || :simple
    @attributes = opts[:attributes] || {}
    @subs = opts[:subs] || []
    raw_source = opts.fetch(:source, nil) || nil
    if !(raw_source = opts[:source])
      @lines = []
    elsif raw_source.is_a? ::String
      @lines = Helpers.normalize_lines_from_string raw_source
    else
      @lines = raw_source.dup
    end
  end

  # Public: Get an rendered version of the block content, performing
  # any substitutions on the content.
  #
  # Examples
  #
  #   doc = Asciidoctor::Document.new
  #   block = Asciidoctor::Block.new(doc, :paragraph,
  #       :source => '_This_ is what happens when you <meet> a stranger in the <alps>!')
  #   block.content
  #   => "<em>This</em> is what happens when you &lt;meet&gt; a stranger in the &lt;alps&gt;!"
  def content
    case @content_model
    when :compound
      super
    when :simple
      apply_subs(@lines * EOL, @subs)
    when :verbatim, :raw
      #((apply_subs @lines.join(EOL), @subs).sub StripLineWiseRx, '\1')

      result = apply_subs @lines, @subs
      if result.size < 2
        result[0]
      else
        result.shift while (first = result[0]) && first.rstrip.empty?
        result.pop while (last = result[-1]) && last.rstrip.empty?
        result * EOL
      end
    else
      warn %(Unknown content model '#{@content_model}' for block: #{to_s}) unless @content_model == :empty
      nil
    end
  end

  # Public: Returns the preprocessed source of this block
  #
  # Returns the a String containing the lines joined together or nil if there
  # are no lines
  def source
    @lines * EOL
  end

  def to_s
    content_summary = @content_model == :compound ? %(blocks: #{@blocks.size}) : %(lines: #{@lines.size})
    %(#{self.class}@#{object_id} { context: #{@context.inspect}, content_model: #{@content_model.inspect}, style: #{@style.inspect}, #{content_summary} })
  end
end
end
