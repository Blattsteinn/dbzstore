class PurchaseSuccessMailer < ApplicationMailer
  def successful_purchase(order, discount)
    @order = order
    @email = order.email
    @discount = discount
    mail(to: @email, subject: "Order #{@order.public_id} delivery")
  end
end
