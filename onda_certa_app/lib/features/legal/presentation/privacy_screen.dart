import 'package:flutter/material.dart';
import 'legal_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Política de Privacidade',
      sections: _sections,
    );
  }
}

const _sections = [
  LegalSection(
    heading: 'Última actualização: Maio de 2026',
    body:
        'A OndaCerta valoriza a tua privacidade. Esta política explica que dados '
        'recolhemos, como os usamos e quais os teus direitos ao abrigo do Regulamento '
        'Geral de Proteção de Dados (RGPD).',
  ),
  LegalSection(
    heading: '1. Responsável pelo Tratamento',
    body:
        'OndaCerta — projecto académico associado ao Parque Natural da Arrábida, Portugal.\n'
        'Contacto: pedro.smarteleira@gmail.com',
  ),
  LegalSection(
    heading: '2. Dados que Recolhemos',
    body:
        '• Dados de conta: endereço de email e nome de utilizador (quando te registas com '
        'email ou Google).\n\n'
        '• Localização: coordenadas GPS quando estás activo numa praia, para calcular '
        'a tua presença e gerar recomendações por proximidade. A posição mostrada no mapa '
        'pode ser aproximada (±300 m) conforme as tuas definições de privacidade.\n\n'
        '• Conteúdo comunitário: alertas que submeteste (tipo, severidade, nota), '
        'votos e propostas de bandeira.\n\n'
        '• Dados de dispositivo: um identificador anónimo de dispositivo, usado apenas '
        'para contas de visitante. Não recolhemos IMEI, número de telefone nem dados '
        'de hardware.\n\n'
        '• Dados de sessão: tokens JWT armazenados localmente de forma segura '
        '(Keychain no iOS, Keystore no Android). Não usamos cookies de sessão.',
  ),
  LegalSection(
    heading: '3. Como Usamos os Dados',
    body:
        '• Mostrar condições das praias e presença de utilizadores em tempo real.\n\n'
        '• Calcular o nível de ocupação e o índice de recomendação por praia.\n\n'
        '• Enviar notificações de proximidade e alertas comunitários, conforme as '
        'tuas preferências.\n\n'
        '• Calcular a tua reputação e nível de contribuidor com base nos alertas '
        'confirmados pela comunidade.\n\n'
        '• Melhorar o serviço com dados estatísticos agregados e anonimizados.',
  ),
  LegalSection(
    heading: '4. Partilha de Dados',
    body:
        'Não vendemos nem partilhamos os teus dados pessoais com terceiros para '
        'fins comerciais.\n\n'
        'O teu nome de utilizador e posição aproximada são visíveis no mapa para '
        'outros utilizadores, se a opção "Partilhar presença" estiver activa nas '
        'tuas definições. Podes desactivá-la a qualquer momento.\n\n'
        'Podemos partilhar dados com prestadores de serviço técnico (alojamento, '
        'envio de notificações push) estritamente necessários para o funcionamento '
        'da app, sob acordos de confidencialidade.',
  ),
  LegalSection(
    heading: '5. Retenção de Dados',
    body:
        'Os teus dados são mantidos enquanto a tua conta estiver activa.\n\n'
        'Alertas expirados são ocultados automaticamente mas mantidos anonimizados '
        'para fins estatísticos durante 12 meses.\n\n'
        'Os dados de localização de sessões anteriores não são persistidos — apenas '
        'a última posição conhecida é armazenada.',
  ),
  LegalSection(
    heading: '6. Os Teus Direitos (RGPD)',
    body:
        'Ao abrigo do RGPD tens direito a:\n\n'
        '• Acesso: exportar todos os teus dados em formato JSON em '
        'Perfil → Privacidade → Exportar dados.\n\n'
        '• Rectificação: alterar o teu nome ou email nas definições de conta.\n\n'
        '• Apagamento: eliminar todos os teus alertas em Privacidade → Apagar '
        'alertas, ou apagar a conta completa em Privacidade → Apagar conta '
        '(irreversível).\n\n'
        '• Portabilidade: os dados exportados estão em formato JSON estruturado.\n\n'
        '• Oposição: desactivar a partilha de localização e presença nas '
        'definições de privacidade.\n\n'
        'Para exercer qualquer direito contacta-nos em pedro.smarteleira@gmail.com.',
  ),
  LegalSection(
    heading: '7. Segurança',
    body:
        'Os tokens de autenticação são armazenados no sistema de armazenamento '
        'seguro do dispositivo. A comunicação com o servidor é feita sobre HTTPS. '
        'As passwords são armazenadas com hash bcrypt.',
  ),
  LegalSection(
    heading: '8. Alterações a esta Política',
    body:
        'Podemos actualizar esta política ocasionalmente. Quando o fizermos, '
        'actualizamos a data no topo desta página. Para alterações significativas, '
        'notificamos através da app.',
  ),
];
