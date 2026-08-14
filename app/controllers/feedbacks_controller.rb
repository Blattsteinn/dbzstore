class FeedbacksController < ApplicationController
    before_action :honeypot_check, only: [:create]

    # Users SHOULD be able to submit with just an public_id
    # We don't need for user's email here.

    before_action :authenticate_admin!, only: [ :edit, :update, :destroy ]

    def index
        @pagy, @feedbacks = pagy(:offset, Feedback.includes(:order).order(created_at: :desc), limit: 10)
    end

    def new
        @feedback = Feedback.new
    end

    def create
        @order = Order.find_by(public_id: params[:feedback][:public_id])
        @feedback = Feedback.new(feedback_params)
        @feedback.order_id = @order.id if @order.present?


        if @feedback.save
            redirect_to feedbacks_path
        else
            render :new, status: :unprocessable_entity
        end
    end

    def edit
        @feedback = Feedback.find(params[:id])
    end

    def update
        @feedback = Feedback.find(params[:id])
        @feedback.update!(feedback_params)
        redirect_to dashboard_feedbacks_path
    end

    def destroy
        @feedback = Feedback.find(params[:id])
        @feedback.destroy
        redirect_to dashboard_feedbacks_path
    end

    private
    def feedback_params
        params.expect(feedback: [ :feedback, :rating ])
    end
end
