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

end
