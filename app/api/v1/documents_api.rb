class V1::DocumentsAPI < Grape::API
  include V1Base

  resources :documents do
    desc %Q{Starts up the process of the document creation.
            The resulting document initially is in the
            \"not ready\" state and awaits the data from the
            OCR pipeline}
    params do
      requires :images, type: Array do
        requires :id, type: String
      end
      requires :metadata, type: JSON do
        requires :title, type: String
        optional :author, type: String
        optional :authority, type: String
        optional :date, type: String
        optional :editor, type: String
        optional :license, type: String
        optional :notes, type: String
        optional :publisher, type: String
      end
    end
    post do
      authorize!

      action! Documents::Create, app: @current_app
    end

    namespace ':id', requirements: { id: uuid_pattern } do
      before do
        authorize!

        @document = Document.find(params[:id])

        if @current_app.id != @document.app_id
          error!('You don\'t own the document', 403)
        end
      end

      desc "Returns document status"
      get 'status' do
        present @document, with: Document::Status
      end

      desc %Q{Returns surfaces, zones and graphemes in a tree format.
             The returning tree can be cut to specific surfaces, zones and/or areas.
             It also allows to specify for which version of the document
             the data should come from. The version can be either a branch name
             or a revision id (uuid).}
      params do
        optional :surface_number, type: Integer
        given :surface_number do
          optional :area, type: Hash do
            requires :ulx, type: Integer
            requires :uly, type: Integer
            requires :lrx, type: Integer
            requires :lry, type: Integer
          end
        end
      end
      get ':revision/tree' do
        data_options = {}

        if uuid_pattern.match?(params[:revision])
          if @document.revisions.where(id: params[:revision]).empty?
            error!('Revision doesn\'t exist', 422)
          end

          data_options[:revision_id] = params[:revision]
        else
          if @document.branches.where(name: params[:revision]).empty?
            error!('Branch doesn\'t exist', 422)
          end

          data_options[:branch_name] = params[:revision]
        end

        if params.key? :surface_number
          data_options[:surface_number] = params[:surface_number]
        else
          if params.key? :area
            error!("Cannot specify an area without a surface number", 422)
          end
        end

        if params.key? :area
          data_options[:area] = Area.new ulx: params[:area][:ulx],
            uly: params[:area][:uly],
            lrx: params[:area][:lrx],
            lry: params[:area][:lry]
        end

        present @document, { with: Document::Tree }.merge(data_options)
      end

      desc 'Lists branches for the document'
      get 'branches' do

      end
    end

  end
end
