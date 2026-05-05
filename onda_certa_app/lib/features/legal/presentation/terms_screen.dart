import 'package:flutter/material.dart';
import 'legal_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Termos de Serviço',
      sections: _sections,
    );
  }
}

const _sections = [
  LegalSection(
    heading: 'Última actualização: Maio de 2026',
    body:
        'Ao utilizares a OndaCerta aceitas estes Termos de Serviço. Lê-os com atenção '
        'antes de criar uma conta ou usar a aplicação.',
  ),
  LegalSection(
    heading: '1. O Serviço',
    body:
        'A OndaCerta é uma aplicação de informação sobre praias do Parque Natural da '
        'Arrábida que agrega dados oficiais de entidades como o IPMA, Instituto '
        'Hidrográfico, APA e Carris Metropolitana, complementados por contribuições '
        'da comunidade de utilizadores.\n\n'
        'Os dados meteorológicos, de marés, qualidade da água e transportes são '
        'fornecidos por fontes externas e têm carácter meramente informativo. '
        'Não substituem a sinalização oficial das praias nem as indicações das '
        'autoridades competentes.',
  ),
  LegalSection(
    heading: '2. Conta de Utilizador',
    body:
        'Podes usar a app como visitante (sem conta), com registo por email/password, '
        'ou com Google Sign-In.\n\n'
        'É tua responsabilidade manter a confidencialidade da tua password e notificar-nos '
        'imediatamente em caso de uso não autorizado da conta.\n\n'
        'Deves ter pelo menos 13 anos para criar uma conta. Utilizadores entre 13 e 16 '
        'anos necessitam do consentimento parental ao abrigo do RGPD.',
  ),
  LegalSection(
    heading: '3. Conteúdo Comunitário',
    body:
        'Ao submeter alertas, propostas de bandeira ou qualquer conteúdo, garantes que:\n\n'
        '• A informação é verdadeira e reflete condições reais que observaste presencialmente.\n\n'
        '• Não estás a praia no momento em que reports, o sistema verifica a tua '
        'presença física através de heartbeat de localização.\n\n'
        '• Não publicarás conteúdo falso, enganoso, ofensivo ou que viole direitos '
        'de terceiros.\n\n'
        'Ao submeter conteúdo concedes à OndaCerta uma licença não exclusiva para '
        'o exibir e utilizar para melhoria do serviço.',
  ),
  LegalSection(
    heading: '4. Sistema de Reputação',
    body:
        'A reputação é calculada com base nas tuas contribuições verificadas pela '
        'comunidade. Alertas confirmados aumentam a reputação; alertas marcados como '
        'falsos reduzem-na.\n\n'
        'Algumas funcionalidades (ex: propor bandeiras) requerem um nível mínimo de '
        'reputação. Reservamo-nos o direito de ajustar o sistema de reputação.',
  ),
  LegalSection(
    heading: '5. Comportamento Proibido',
    body:
        'É proibido:\n\n'
        '• Submeter alertas falsos ou manipular votos de forma coordenada.\n\n'
        '• Usar ferramentas automáticas (bots) para gerar presença artificial ou '
        'conteúdo em massa.\n\n'
        '• Tentar aceder a contas de outros utilizadores ou comprometer a '
        'segurança do serviço.\n\n'
        '• Recolher dados de outros utilizadores sem consentimento.\n\n'
        'A violação destas regras pode resultar na suspensão ou eliminação da conta '
        'sem aviso prévio.',
  ),
  LegalSection(
    heading: '6. Limitação de Responsabilidade',
    body:
        'A OndaCerta não se responsabiliza por:\n\n'
        '• Decisões tomadas com base nos dados exibidos na app. As condições do mar '
        'podem mudar rapidamente, consulta sempre a sinalização oficial na praia.\n\n'
        '• Imprecisões nos dados fornecidos por APIs externas.\n\n'
        '• Danos causados por conteúdo submetido por outros utilizadores.\n\n'
        '• Interrupções de serviço por manutenção ou problemas técnicos.',
  ),
  LegalSection(
    heading: '7. Propriedade Intelectual',
    body:
        'O nome "OndaCerta", o logótipo e o código da aplicação são propriedade '
        'dos seus criadores. Os dados das APIs externas são propriedade das '
        'respectivas entidades (IPMA, IH, APA, Carris Metropolitana).\n\n'
        'O conteúdo comunitário (alertas, votos) permanece de domínio público '
        'no que respeita à informação factual sobre condições das praias.',
  ),
  LegalSection(
    heading: '8. Alterações e Rescisão',
    body:
        'Podemos modificar ou descontinuar o serviço, ou actualizar estes termos, '
        'a qualquer momento. Notificaremos os utilizadores registados sobre '
        'alterações significativas.\n\n'
        'Podes eliminar a tua conta a qualquer momento em Perfil → Privacidade → '
        'Apagar conta.',
  ),
  LegalSection(
    heading: '9. Lei Aplicável',
    body:
        'Estes termos regem-se pela lei portuguesa. Qualquer litígio será '
        'submetido à jurisdição dos tribunais portugueses.',
  ),
  LegalSection(
    heading: '10. Contacto',
    body: 'Para questões sobre estes termos: pedro.smarteleira@gmail.com',
  ),
];
