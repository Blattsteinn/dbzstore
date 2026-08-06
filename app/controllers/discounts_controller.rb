class DiscountsController < ApplicationController
  before_action :authenticate_admin!

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

    if @discount.update(params.expect(discount: [:code, :amount, :remaining]))
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

  private
  
  def discount_params
    params.expect(discount: [:code, :amount])
  end

end
