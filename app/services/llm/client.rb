require "net/http"
require "json"

module Llm
  # Cliente de LLM agnostico de provedor. Usa Anthropic ou OpenAI conforme
  # as variaveis de ambiente disponiveis. Sem chave configurada, retorna nil
  # e o chamador recorre a heuristica -- assim a aplicacao roda offline.
  module Client
    module_function

    def available?
      ENV["ANTHROPIC_API_KEY"].present? || ENV["OPENAI_API_KEY"].present?
    end

    # Envia system + prompt e retorna o texto da resposta (esperado: JSON).
    # Retorna nil em caso de indisponibilidade ou erro de rede.
    def complete(system:, prompt:, max_tokens: 1024)
      if ENV["ANTHROPIC_API_KEY"].present?
        anthropic(system, prompt, max_tokens)
      elsif ENV["OPENAI_API_KEY"].present?
        openai(system, prompt, max_tokens)
      end
    rescue StandardError => e
      Rails.logger.warn("Llm::Client erro: #{e.class}: #{e.message}")
      nil
    end

    def anthropic(system, prompt, max_tokens)
      res = post(
        "https://api.anthropic.com/v1/messages",
        {
          model: ENV.fetch("LLM_MODEL", "claude-sonnet-4-5"),
          max_tokens: max_tokens,
          system: system,
          messages: [{ role: "user", content: prompt }]
        },
        "x-api-key" => ENV["ANTHROPIC_API_KEY"],
        "anthropic-version" => "2023-06-01"
      )
      res.dig("content", 0, "text")
    end

    def openai(system, prompt, max_tokens)
      res = post(
        "https://api.openai.com/v1/chat/completions",
        {
          model: ENV.fetch("LLM_MODEL", "gpt-4o-mini"),
          max_tokens: max_tokens,
          messages: [
            { role: "system", content: system },
            { role: "user", content: prompt }
          ]
        },
        "Authorization" => "Bearer #{ENV['OPENAI_API_KEY']}"
      )
      res.dig("choices", 0, "message", "content")
    end

    def post(url, body, headers)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      headers.each { |k, v| req[k] = v }
      req.body = body.to_json
      JSON.parse(http.request(req).body)
    end
  end
end
