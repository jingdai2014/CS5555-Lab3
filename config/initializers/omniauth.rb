Rails.application.config.middleware.use OmniAuth::Builder do
  provider :fitbit, '95ecbb851b8165022e445ff61c5248e5', '58bafd75ecc502521569c8613d6ca33d'
end