# frozen_string_literal: true

module Templates
  # Wippli: heading-anchored field resolver.
  #
  # Each signing block is introduced by a party heading that already names the
  # party once - "WIPPLI ...", "COUNTERPARTY ...", "PROCESSOR/CONTROLLER ...",
  # "... (Assignee)/(Assignor)" - so field lines stay clean ("Name:", "Signature:").
  # The resolver walks the document in reading order across EVERY page, tracks the
  # current party from the most recent heading, and binds each ruled field line to
  # it. This fixes the previous single-page parser that dropped Party 1 and
  # multi-page blocks, without repeating a role tag on every line.
  #
  # Party 1 = submitters[0], Party 2 = submitters[1]. The keyword sets below map
  # the heading wording to a slot and can be extended as new role words appear.
  module ResolveAnchorFields
    PARTY1 = /\b(WIPPLI|PROCESSOR|ASSIGNEE|DISCLOSER)\b/i
    PARTY2 = /\b(COUNTERPARTY|CONTROLLER|ASSIGNOR|RECIPIENT)\b/i
    # explicit override wins if a heading spells the slot out: "Party 1" / "Party 2"
    PARTY_N = /\bParty\s*(\d+)\b/i
    # a field line starts with its type word and carries a ruled underscore line
    FIELD_HEAD = /\A\s*(Signature|Name|Title|Date)\b/i
    # the signatures section boundary. Detection is confined to it so that body
    # prose (which mentions "Wippli" etc. constantly) can never set the current
    # party, and so that fill-in blanks elsewhere in the body are never mistaken
    # for signature fields. A party heading is also required to be short - real
    # headings, not sentences that happen to contain a keyword.
    SIG_SECTION = /\ASignatures?\z/i
    MAX_HEADING_LEN = 80

    LINE_Y_TOLERANCE = 0.004
    MIN_UNDERSCORES  = 2
    UNDERSCORE_GAP   = 0.02
    SIG_MIN_H        = 0.045
    SIG_MAX_H        = 0.09

    module_function

    # io: PDF IO. submitters: template.submitters (index 0 = Party 1, 1 = Party 2).
    def call(io, submitters:, attachment_uuid: nil)
      doc = Pdfium::Document.open_bytes(io.read)
      fields = []
      current = nil    # submitter index of the block we are inside
      in_sig = false   # only detect once we are inside the signatures section

      doc.page_count.times do |page_number|
        page = doc.get_page(page_number)
        begin
          nodes = page.text_nodes.to_a.sort_by { |n| [n.y.round(3), n.x] }
          next if nodes.empty?

          underscores = underscore_boxes(nodes)

          lines_for(nodes).each do |line|
            text = line.map(&:content).join(' ').gsub(/\s+/, ' ').strip
            next if text.empty?

            unless in_sig
              in_sig = true if text.match?(SIG_SECTION)
              next
            end

            slot = party_slot(text, submitters)
            unless slot.nil?
              current = slot
              next
            end

            head = text.match(FIELD_HEAD)
            next unless head && current

            area = field_area_for(line, underscores)
            next if area.nil? # only real ruled lines become fields

            type = type_for(head[1])
            area = grow_signature(area) if type == 'signature'
            submitter = submitters[current]
            next if submitter.blank?

            fields << {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => head[1].capitalize,
              'type' => type,
              'required' => type == 'signature',
              'preferences' => {},
              'areas' => [area.merge('page' => page_number, 'attachment_uuid' => attachment_uuid)]
            }
          end
        ensure
          page.close
        end
      end

      fields
    ensure
      doc&.close
    end

    # Returns the submitter index if this line is a party heading, else nil.
    # Conservative: never guesses. An explicit "Party N" wins; otherwise the line
    # must be short (a heading, not a sentence) and match exactly one party's
    # keyword set - a line matching both is ambiguous and is left for the next,
    # unambiguous heading rather than risk assigning fields to the wrong signer.
    def party_slot(text, submitters)
      if (m = text.match(PARTY_N))
        idx = m[1].to_i - 1
        return idx if submitters[idx]
      end
      # field lines are never headings; overly long lines are prose, not headings
      return nil if text.match?(FIELD_HEAD) || text.length > MAX_HEADING_LEN

      p1 = text.match?(PARTY1)
      p2 = text.match?(PARTY2) && !submitters[1].nil?
      return nil if p1 && p2 # ambiguous - do not guess

      return 0 if p1
      return 1 if p2

      nil
    end

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

    def underscore_boxes(nodes)
      boxes = []
      i = 0
      while i < nodes.length
        node = nodes[i]
        if node.content != '_'
          i += 1
          next
        end
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

    # The ruled underscore run on the field line, to the right of the label.
    def field_area_for(line, underscores)
      line_y = line.map(&:y).min
      line_h = line.map(&:h).max
      box = underscores.find do |b|
        (b['y'] - line_y).abs <= (line_h + LINE_Y_TOLERANCE) && (b['x'] + b['w']) > line.first.x
      end
      box&.dup
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
