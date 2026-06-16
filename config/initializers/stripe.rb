# Configura a chave do Stripe quando presente. Sem a chave, a aplicacao usa
# um gateway fake (ver Payments::Gateway) para permitir demo sem credenciais.
Stripe.api_key = ENV["STRIPE_SECRET_KEY"] if ENV["STRIPE_SECRET_KEY"].present?
