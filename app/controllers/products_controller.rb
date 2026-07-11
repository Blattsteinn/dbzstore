class ProductsController < ApplicationController
    before_action :authenticate_admin!, except: [:index, :show]
    before_action :set_game, only: [:index, :show, :show_hero, :show_minimal, :show_split, :show_card, :show_gallery]
    before_action :set_product_for_designs, only: [:show_hero, :show_minimal, :show_split, :show_card, :show_gallery]

    def index
        @products = Product.visible.includes(:variants, product_images: :image_attachment)
        @products = @products.where(game_name: params[:game])
        # @products = @products.where("title ILIKE ?", "%#{params[:product_name]}%") if params[:product_name].present?
        @products = @products.order(priority: :asc)

        ahoy.track "Viewed products", game: @game&.name
    end

    def show
        @product = Product.includes(:variants, product_images: :image_attachment).find(params[:id])
        unless @product.visibility == "live"
            redirect_to products_path
        end
    end

    def new
        @product = Product.new
        @product.product_images.build
        @product.variants.build
    end

    def create
        @product = Product.new(product_params)
        if @product.save 
            redirect_to dashboard_products_path
        else
            render :new, status: :unprocessable_entity
        end
    end

    def edit
        @product = Product.includes(:variants, product_images: :image_attachment).find(params[:id])
    end

    def update
        @product = Product.find(params[:id])
        @product.assign_attributes(product_params)


        if @product.save
            flash[:successful_edit] = "Saved successfully."
            redirect_to dashboard_products_path
        else
            flash.now[:fail_edit] = "Failed to save successfully."
            render :edit, status: :unprocessable_entity
        end
    end

    def product_visibility
        @product = Product.find(params[:id])
        new_visibility = @product.visibility == "live" ? "hidden" : "live"
        @product.update!(visibility: new_visibility)
        redirect_to dashboard_products_path
    end

    def duplicate_product
        @original_p = Product.includes(:variants).find(params[:id])
        @original_v = @original_p.variants

        @product = Product.create!(@original_p.attributes.except("id","created_at","updated_at"))
        @product.update!(title: @product.title + " Copy")
        @original_v.each do |variant|
            v = Variant.create!(variant.attributes.except("id", "created_at","updated_at"))
            v.update!(product_id: @product.id)
        end

        redirect_to edit_product_path(@product)
    end

    def destroy
        @product = Product.find(params[:id])
        title = @product.title
        @product.destroy!
        flash[:notice] = "\"#{title}\" deleted — existing orders preserved."
        redirect_to dashboard_products_path
    end

    # ---- Alternative product view designs ----

    def show_hero
        render :show_hero
    end

    def show_minimal
        render :show_minimal
    end

    def show_split
        render :show_split
    end

    def show_card
        render :show_card
    end

    def show_gallery
        render :show_gallery
    end

    private
    def product_params
        params.expect(product: [:title, :visibility, :description, :payment_type, :deliverables, :game_name, :priority,
        product_images_attributes: [[:image, :priority, :_destroy, :id]],
        variants_attributes: [[:stock, :price, :title, :description, :_destroy, :id]]
        ])
    end

    def set_game
        @game = Game.find_by!(name: params[:game]) if params[:game].present?
    end

    #solution proposed by AI, name is game's name is derived from product if smth fails
    # def set_game
    #     @game = if params[:game].present?
    #         Game.find_by!(name: params[:game])
    #     elsif params[:id].present?
    #         product = Product.find_by(id: params[:id])
    #         Game.find_by(name: product&.game_name) if product
    #     end
    # end

    def set_product_for_designs
        @product = Product.includes(:variants, product_images: :image_attachment).find(params[:id])
        redirect_to products_path unless @product.visibility == "live"
    end

end
