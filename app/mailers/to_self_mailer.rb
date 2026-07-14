class ToSelfMailer < ApplicationMailer
    def mail_self(order)
        @order = order
        @email = order.email

        @price = convert_from_cents(@order.order_items.first.price)
        mail(to: "dokkanriftmanagement@tuta.com", subject: "Order received, #{@price} EUR")
    end
end
