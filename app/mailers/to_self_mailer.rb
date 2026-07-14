class ToSelfMailer < ApplicationMailer
    def mail_self(order)
        @order = order
        @email = "dokkanriftmanagement@tuta.com"

        @price = @order.order_items.first.price / 100.0
        mail(to: @email, subject: "Order received, #{@price} EUR")
    end
end
