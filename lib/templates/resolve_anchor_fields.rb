# frozen_string_literal: true

module Templates
  # Wippli: anchor-based field resolver.
  #
  # The signing document carries a self-describing anchor on each field line, e.g.
  #   "Signature (Party 1): ______"   "Name (Party 2): ______"
  # The field TYPE comes from the leading word (Name/Title/Date/Signature) and the
  # ROLE from "(Party N)". This binds each field to TEXT, not coordinates, so it
  # survives any layout change in the source (Outline) — and it scans EVERY page,
  # unlike the previous single-page parser that dropped Party 1 / multi-page fields.
  module ResolveAnchorFields
    # word + "(Party N)"; whitespace is tolerant because PDF text nodes may join
    # with or without spaces.
    ANCHOR = /\b(Signature|Name|Title|Date)\s*\(\s*Party\s*(\d+)\s*\)/i
    LINE_Y_TOLERANCE = 0.004  # ~1.2mm on A4 - group text nodes into the same line
    MIN_UNDERSCORES  = 2
    UNDERSCORE_GAP   = 0.02   # max x-gap between consecutive underscore glyphs
    SIG_MIN_H        = 0.045  # signatures get a taller box than a text line
    SIG_MAX_H        = 0.09

    module_function

    # io: an IO for the PDF. submitters: template.submitters array (ordered;
    # index 0 = Party 1, index 1 = Party 2, ...). Returns a fields array shaped
    # like the rest of the pipeline expects.
    def call(io, submitters:, attachment_uuid: nil)
      doc = Pdfium::Document.open_bytes(io.read)
      fields = []

      doc.page_count.times do |page_number|
        page = doc.get_page(page_number)
        begin
          resolve_page(page, page_number, submitters, attachment_uuid, fields)
        ensure
          page.close
        end
      end

      fields
    ensure
      doc&.close
    end

    def resolve_page(page, page_number, submitters, attachment_uuid, fields)
      nodes = page.text_nodes.to_a.sort_by { |n| [n.y.round(3), n.x] }
      return if nodes.empty?

      underscores = underscore_boxes(nodes)

      lines_for(nodes).each do |line|
        text = line.map(&:content).join
        match = text.match(ANCHOR)
        next unless match

        role_index = match[2].to_i - 1
        submitter  = submitters[role_index]
        next if submitter.blank?

        type = type_for(match[1])

        area = field_area_for(line, underscores)
        next if area.nil?

        area = grow_signature(area) if type == 'signature'

        fields << {
          'uuid' => SecureRandom.uuid,
          'submitter_uuid' => submitter['uuid'],
          'name' => "#{match[1].capitalize} (Party #{match[2]})",
          'type' => type,
          'required' => type == 'signature',
          'preferences' => {},
          'areas' => [area.merge('page' => page_number, 'attachment_uuid' => attachment_uuid)]
        }
      end
    end

    # Group text nodes (already sorted) into visual lines by y proximity.
    def lines_for(nodes)
      lines = []
      current = []
      current_y = nil

      nodes.each do |node|
        if current_y.nil? || (node.y - current_y).abs <= LINE_Y_TOLERANCE
          current << node
          current_y ||= node.y
        else
          lines << current unless current.empty?
          current = [node]
          current_y = node.y
        end
      end
      lines << current unless current.empty?
      lines.each { |l| l.sort_by!(&:x) }
    end

    # Ruled underscore runs across the whole page (>= MIN_UNDERSCORES '_' glyphs).
    def underscore_boxes(nodes)
      boxes = []
      i = 0
      while i < nodes.length
        node = nodes[i]
        (i += 1) and next if node.content != '_'

        x1 = node.x; y1 = node.y; x2 = node.endx; y2 = node.endy; count = 1
        j = i + 1
        while j < nodes.length && nodes[j].content == '_'
          nxt = nodes[j]
          break if (nxt.x - x2) > UNDERSCORE_GAP || (nxt.y - y1).abs > node.h * 0.5
          x2 = nxt.endx; y2 = [y2, nxt.endy].max; y1 = [y1, nxt.y].min; count += 1
          j += 1
        end
        boxes << { 'x' => x1, 'y' => y1, 'w' => x2 - x1, 'h' => y2 - y1 } if count >= MIN_UNDERSCORES
        i = j
      end
      boxes
    end

    # The field box is the ruled underscore run on the anchor's own line, to the
    # right of the label. Falls back to a box after the label if no rule is drawn.
    def field_area_for(line, underscores)
      line_y = line.map(&:y).min
      line_h = line.map(&:h).max
      label_end = line.map(&:endx).max

      box = underscores.find do |b|
        (b['y'] - line_y).abs <= (line_h + LINE_Y_TOLERANCE) && (b['x'] + b['w']) > line.first.x
      end
      return box.dup if box

      # no drawn rule: place a default box after the label text
      { 'x' => label_end + 0.01, 'y' => line_y, 'w' => 0.35, 'h' => line_h }
    end

    def grow_signature(area)
      h = [[area['h'] * 3, SIG_MIN_H].max, SIG_MAX_H].min
      area.merge('h' => h, 'y' => (area['y'] + area['h']) - h)
    end

    def type_for(word)
      case word.downcase
      when 'signature' then 'signature'
      when 'date' then 'date'
      else 'text'
      end
    end
  end
end
