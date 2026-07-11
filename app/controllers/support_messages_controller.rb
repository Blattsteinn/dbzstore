class SupportMessagesController < ApplicationController
    before_action :authenticate_admin!, only: [:index, :show, :destroy, :update]
    before_action :honeypot_check, only: [:create]
    
    def index
        @support_messages = SupportMessage.all.includes(:order)
    end

    def show
        @support_message = SupportMessage.find(params[:id])
    end

    
    def new
        @support_message = SupportMessage.new
    end

    def create
        @support_message = SupportMessage.new(support_message_params)
        if params[:support_message][:public_id].present?
            order = Order.find_by(public_id: params[:support_message][:public_id])
            @support_message.order = order if order
        end
        if @support_message.save
            redirect_to new_support_message_path
        else
            render :new, status: :unprocessable_entity
        end
    end

    def destroy
        @support_message = SupportMessage.find(params[:id])
        @support_message.destroy
    end

    def update
        @support_message = SupportMessage.find(params[:id])
        @support_message.update!(status: params[:status])
        redirect_to support_message_path(@support_message)
    end

    private
    def support_message_params
        params.expect(support_message: [:title, :email, :message])
    end

end
