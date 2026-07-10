# Preview all emails at http://localhost:3000/rails/mailers/purchase_success_mailer
class PurchaseSuccessMailerPreview < ActionMailer::Preview
    def successful_purchase
    order = Order.joins(:order_items).last || Order.new(public_id: "DEMO-XXXX")
    PurchaseSuccessMailer.successful_purchase(order)
  end
end
