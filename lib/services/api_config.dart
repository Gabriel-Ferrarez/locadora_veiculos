/// Endereço da API publicada no Render.
///
/// Para simular a API indisponível (Teste 2 do enunciado), troque
/// temporariamente por um endereço inválido, por exemplo:
///   const String apiBaseUrl = 'https://endereco-invalido.onrender.com';
/// Depois restaure o valor correto e use "Sincronizar pendentes" (Teste 3).
const String apiBaseUrl = 'https://locadora-veiculos-api.onrender.com';

/// O plano gratuito do Render "dorme" sem uso e leva alguns segundos para
/// acordar na primeira requisição. Um tempo maior evita marcar como pendente
/// um cadastro que só estava esperando o servidor acordar.
const Duration apiTimeout = Duration(seconds: 30);
