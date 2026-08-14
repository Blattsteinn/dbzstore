class FaqsController < ApplicationController
  before_action :authenticate_admin!, except: [:index]

  def index
    @faqs = Faq.all
  end

  def new
    @faq = Faq.new
  end

  def create
    @faq = Faq.new(faq_params)
    if @faq.save
      redirect_to dashboard_faqs_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @faq = Faq.find(params[:id])
    @faq.destroy
    redirect_to dashboard_faqs_path
  end

  def edit
      @faq = Faq.find(params[:id])
  end

  def update
    @faq = Faq.find(params[:id])
    @faq.update(faq_params)
    if @faq.save
      redirect_to dashboard_faqs_path
    else
      render :update, status: :unprocessable_entity
    end
  end

  private
  def faq_params
    params.expect(faq: [ :question, :answer ])
  end
end
