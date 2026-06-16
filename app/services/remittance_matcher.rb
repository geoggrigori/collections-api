# Concilia um aviso de remessa (remittance advice) em texto livre com as
# faturas em aberto do cliente. Usa o LLM quando ha chave configurada; caso
# contrario, recorre a uma heuristica deterministica (casa numeros de fatura
# citados no texto). Classe separada do model Remittance para evitar colisao
# de constante.
class RemittanceMatcher
  Result = Struct.new(:invoice_numbers, :confidence, :source, :reasoning, keyword_init: true)

  CONFIDENCE_FLOOR = 0.6

  def self.call(customer:, raw_text:, amount_cents:)
    new(customer, raw_text, amount_cents).call
  end

  def initialize(customer, raw_text, amount_cents)
    @customer = customer
    @raw_text = raw_text.to_s
    @amount_cents = amount_cents
  end

  def call
    open_invoices = @customer.invoices.unpaid.order(:due_date)
    llm_result(open_invoices) || heuristic_result(open_invoices)
  end

  private

  def heuristic_result(open_invoices)
    numbers = open_invoices.pluck(:invoice_number)
    found = numbers.select { |n| @raw_text.include?(n) }
    Result.new(
      invoice_numbers: found,
      confidence: found.any? ? CONFIDENCE_FLOOR : 0.0,
      source: "heuristic",
      reasoning: found.any? ? "Numeros de fatura encontrados no texto." : "Nenhum numero de fatura reconhecido."
    )
  end

  def llm_result(open_invoices)
    return nil unless Llm::Client.available?

    catalog = open_invoices.limit(100).map do |i|
      { invoice_number: i.invoice_number, balance_cents: i.balance_cents, due_date: i.due_date.iso8601 }
    end

    raw = Llm::Client.complete(system: system_prompt, prompt: user_prompt(catalog))
    return nil if raw.blank?

    json = JSON.parse(extract_json(raw))
    Result.new(
      invoice_numbers: Array(json["invoice_numbers"]),
      confidence: json["confidence"].to_f,
      source: "llm",
      reasoning: json["reasoning"].to_s
    )
  rescue JSON::ParserError
    nil
  end

  def system_prompt
    "Voce concilia avisos de remessa de contas a receber. " \
      "Dado o texto do cliente e a lista de faturas em aberto, identifique " \
      "exatamente quais faturas estao sendo pagas. Responda SOMENTE com JSON valido."
  end

  def user_prompt(catalog)
    <<~PROMPT
      Texto da remessa do cliente:
      """#{@raw_text}"""

      Valor recebido (em centavos): #{@amount_cents}

      Faturas em aberto (JSON):
      #{catalog.to_json}

      Responda no formato:
      {"invoice_numbers": ["<invoice_number>", ...], "confidence": <0.0 a 1.0>, "reasoning": "<breve>"}
    PROMPT
  end

  def extract_json(text)
    text[/\{.*\}/m] || text
  end
end
