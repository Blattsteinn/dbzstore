# Preview all emails at http://localhost:3000/rails/mailers/purchase_success_mailer
class PurchaseSuccessMailerPreview < ActionMailer::Preview
    def successful_purchase
    order = Order.joins(:order_items).last || Order.new(public_id: "DEMO-XXXX")
    discount = Discount.new(code: "DEMO20OFF", amount: 1, remaining: 1, percentage: 20)
    PurchaseSuccessMailer.successful_purchase(order, discount)
  end
end
