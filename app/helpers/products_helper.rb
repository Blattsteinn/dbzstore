require 'redcarpet'

MARKDOWN_RENDERER = Redcarpet::Markdown.new(
  Redcarpet::Render::HTML.new(hard_wrap: true, filter_html: true, link_attributes: { target: "_blank", rel: "noopener noreferrer" }),
  autolink: true, tables: true
)

module ProductsHelper
    def convert_from_cents(cents)
        return 0 if cents.nil?
        cents /= 100.0
    end

    def markdown(text)
        sanitize(MARKDOWN_RENDERER.render(text))
    end

    # Admin-authored markdown descriptions may use level-1 headings (#), but
    # product pages already have one h1 (the product title). Demote every
    # heading in the rendered HTML by one level so pages keep a single h1.
    def demote_headings(html)
        html.gsub(%r{<(/?)h(\d)([ >])}) do |match|
            level = [match[2].to_i + 1, 6].min
            "<#{match[1]}h#{level}#{match[3]}"
        end
    end

end
