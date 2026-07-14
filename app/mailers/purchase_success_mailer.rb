class PurchaseSuccessMailer < ApplicationMailer
  def successful_purchase(order)
    @order = order
    @email = order.email
    mail(to: @email, subject: "Order #{@order.public_id} delivery")
  end

end
