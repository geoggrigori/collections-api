module Api
  module V1
    # Controller base da API v1: paginacao, tratamento de erros consistente
    # e envelope JSON padronizado para toda a versao.
    class BaseController < ApplicationController
      include Pagy::Backend

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      # Renderiza uma colecao paginada com metadados em cabecalhos (pagy headers)
      # e tambem no corpo, para clientes que preferem ler do JSON.
      def render_collection(scope, serializer)
        pagy_obj, records = pagy(scope)
        pagy_headers_merge(pagy_obj)
        render json: {
          data: records.map { |r| serializer.call(r) },
          meta: {
            page: pagy_obj.page,
            limit: pagy_obj.limit,
            count: pagy_obj.count,
            pages: pagy_obj.pages
          }
        }
      end

      def render_resource(record, serializer, status: :ok)
        render json: { data: serializer.call(record) }, status: status
      end

      def not_found(error)
        render json: { error: { code: "not_found", message: error.message } },
               status: :not_found
      end

      def unprocessable_entity(error)
        render json: {
          error: {
            code: "unprocessable_entity",
            message: "Falha de validacao",
            details: error.record.errors.to_hash(true)
          }
        }, status: :unprocessable_entity
      end

      def bad_request(error)
        render json: { error: { code: "bad_request", message: error.message } },
               status: :bad_request
      end
    end
  end
end
