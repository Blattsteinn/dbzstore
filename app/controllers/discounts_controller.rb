class DiscountsController < ApplicationController
  before_action :authenticate_admin!, except: [:check_discount]

  def index
    @discounts = Discount.all
  end

  def show
    @discount = Discount.find(params[:id])
  end

  def new
    @discount = Discount.new
  end

  def create
    @discount = Discount.new(discount_params)
    @discount.remaining = @discount.amount
    
    if @discount.save
      flash[:notice] = "Created successfully."
      redirect_to dashboard_discounts_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @discount = Discount.find(params[:id])
  end

  def update
    @discount = Discount.find(params[:id])

    if @discount.update(params.expect(discount: [:code, :amount, :remaining, :percentage]))
      flash[:notice] = "Saved successfully."
      redirect_to dashboard_discounts_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @discount = Discount.find(params[:id])
    @discount = @discount.destroy
    redirect_to discounts_path
  end

  def check_discount
    discount = Discount.find_by(code: params[:code])
    if discount&.available?
      render json: { valid: true, percentage: discount.percentage}
    else
      render json: { valid: false }
    end
  end

  private
  
  def discount_params
    params.expect(discount: [:code, :amount, :percentage])
  end

end
