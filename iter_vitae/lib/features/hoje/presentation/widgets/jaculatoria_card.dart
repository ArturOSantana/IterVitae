import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iter_vitae/core/theme/app_colors.dart';
import 'package:iter_vitae/core/widgets/section_pilcrow.dart';

/// Card da jaculatória do dia.
///
/// A jaculatória é determinada deterministicamente pelo dia do ano
/// (dayOfYear % total), garantindo que mude a cada dia e seja igual
/// para todos os usuários no mesmo dia.
class JaculatoriaDoDia extends StatelessWidget {
  const JaculatoriaDoDia({super.key, this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final today = date ?? DateTime.now();
    final jaculatoria = _jaculatoriaParaData(today);

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionPilcrow(label: 'jaculatória do dia'),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jaculatoria.texto,
                style: GoogleFonts.fraunces(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                jaculatoria.tema,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Modelo interno ────────────────────────────────────────────────────────────

class _Jaculatoria {
  const _Jaculatoria(this.texto, this.tema);
  final String texto;
  final String tema;
}

// ── Selecção determinística ───────────────────────────────────────────────────

_Jaculatoria _jaculatoriaParaData(DateTime date) {
  final dayOfYear = _diaDoAno(date);
  final idx = dayOfYear % _jaculatorias.length;
  return _jaculatorias[idx];
}

int _diaDoAno(DateTime date) {
  final startOfYear = DateTime(date.year, 1, 1);
  return date.difference(startOfYear).inDays;
}

// ── Lista de jaculatórias ─────────────────────────────────────────────────────

const List<_Jaculatoria> _jaculatorias = [
  // A Jesus Cristo
  _Jaculatoria('Jesus, eu confio em Vós.', 'a Jesus Cristo'),
  _Jaculatoria('Meu Jesus, eu Vos amo.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, tende piedade de mim.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, manso e humilde de coração, fazei meu coração semelhante ao Vosso.', 'a Jesus Cristo'),
  _Jaculatoria('Meu Senhor e meu Deus!', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, aumentai a minha fé.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, aumentai em mim a esperança.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, ensinai-me a amar.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, sede a minha força.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, sede o meu refúgio.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, sede o centro da minha vida.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, conduzi-me pelo Vosso caminho.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, não permitais que eu me afaste de Vós.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, livrai-me de todo pecado.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, dai-me um coração puro.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, dai-me perseverança.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, dai-me a graça de Vos seguir.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, que eu diminua para que Vós cresçais.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, seja feita em mim a Vossa vontade.', 'a Jesus Cristo'),
  _Jaculatoria('Jesus, entrego tudo a Vós.', 'a Jesus Cristo'),
  // Misericórdia e conversão
  _Jaculatoria('Jesus, Filho de Davi, tende piedade de mim, pecador.', 'misericórdia e conversão'),
  _Jaculatoria('Senhor, perdoai os meus pecados.', 'misericórdia e conversão'),
  _Jaculatoria('Meu Deus, arrependo-me de todo coração.', 'misericórdia e conversão'),
  _Jaculatoria('Senhor, criai em mim um coração puro.', 'misericórdia e conversão'),
  _Jaculatoria('Jesus, lavai-me com a Vossa misericórdia.', 'misericórdia e conversão'),
  _Jaculatoria('Senhor, convertei o meu coração.', 'misericórdia e conversão'),
  _Jaculatoria('Meu Deus, dai-me a graça de não pecar mais.', 'misericórdia e conversão'),
  _Jaculatoria('Jesus, libertai-me de todo mal.', 'misericórdia e conversão'),
  _Jaculatoria('Senhor, fortalecei-me contra as tentações.', 'misericórdia e conversão'),
  _Jaculatoria('Jesus, sede minha salvação.', 'misericórdia e conversão'),
  _Jaculatoria('Senhor, não olheis os meus pecados, mas a minha fé.', 'misericórdia e conversão'),
  _Jaculatoria('Meu Deus, tende misericórdia de mim.', 'misericórdia e conversão'),
  _Jaculatoria('Jesus, ajudai-me a levantar depois das minhas quedas.', 'misericórdia e conversão'),
  _Jaculatoria('Senhor, ensinai-me a reconhecer meus erros.', 'misericórdia e conversão'),
  _Jaculatoria('Jesus, fazei-me fiel até o fim.', 'misericórdia e conversão'),
  // Nossa Senhora
  _Jaculatoria('Santa Maria, rogai por nós.', 'Nossa Senhora'),
  _Jaculatoria('Maria, minha Mãe, conduzi-me a Jesus.', 'Nossa Senhora'),
  _Jaculatoria('Nossa Senhora, rogai por mim.', 'Nossa Senhora'),
  _Jaculatoria('Mãe de Deus, intercedei por nós.', 'Nossa Senhora'),
  _Jaculatoria('Imaculado Coração de Maria, sede a minha salvação.', 'Nossa Senhora'),
  _Jaculatoria('Maria Santíssima, protegei-me.', 'Nossa Senhora'),
  _Jaculatoria('Nossa Senhora, cobri-me com o vosso manto.', 'Nossa Senhora'),
  _Jaculatoria('Maria, ensinai-me a dizer "sim" a Deus.', 'Nossa Senhora'),
  _Jaculatoria('Maria, ajudai-me a guardar Jesus no meu coração.', 'Nossa Senhora'),
  _Jaculatoria('Mãe Santíssima, aumentai minha confiança em Deus.', 'Nossa Senhora'),
  _Jaculatoria('Nossa Senhora, livrai-me do pecado.', 'Nossa Senhora'),
  _Jaculatoria('Maria, sede minha guia no caminho da santidade.', 'Nossa Senhora'),
  _Jaculatoria('Santa Mãe de Deus, rogai por nós pecadores.', 'Nossa Senhora'),
  _Jaculatoria('Maria, levai-me sempre para mais perto de Cristo.', 'Nossa Senhora'),
  _Jaculatoria('Nossa Senhora, intercedei pelas minhas necessidades.', 'Nossa Senhora'),
  // Espírito Santo
  _Jaculatoria('Vinde, Espírito Santo.', 'Espírito Santo'),
  _Jaculatoria('Espírito Santo, iluminai-me.', 'Espírito Santo'),
  _Jaculatoria('Espírito Santo, guiai-me.', 'Espírito Santo'),
  _Jaculatoria('Espírito Santo, fortalecei-me.', 'Espírito Santo'),
  _Jaculatoria('Espírito Santo, santificai-me.', 'Espírito Santo'),
  _Jaculatoria('Espírito Santo, concedei-me sabedoria.', 'Espírito Santo'),
  _Jaculatoria('Espírito Santo, concedei-me discernimento.', 'Espírito Santo'),
  _Jaculatoria('Espírito Santo, aumentai minha fé.', 'Espírito Santo'),
  _Jaculatoria('Espírito Santo, inflamai meu coração.', 'Espírito Santo'),
  _Jaculatoria('Espírito Santo, ensinai-me a rezar.', 'Espírito Santo'),
  _Jaculatoria('Espírito Santo, fazei de mim instrumento de Deus.', 'Espírito Santo'),
  _Jaculatoria('Espírito Santo, renovai o meu coração.', 'Espírito Santo'),
  // Santos
  _Jaculatoria('São José, rogai por nós.', 'São José e os santos'),
  _Jaculatoria('São José, guardai a minha família.', 'São José e os santos'),
  _Jaculatoria('São José, ensinai-me a trabalhar com amor.', 'São José e os santos'),
  _Jaculatoria('São Miguel Arcanjo, defendei-nos no combate.', 'São José e os santos'),
  _Jaculatoria('Santo Anjo da Guarda, protegei-me.', 'São José e os santos'),
  _Jaculatoria('Santa Terezinha do Menino Jesus, rogai por nós.', 'São José e os santos'),
  _Jaculatoria('São Bento, rogai por nós.', 'São José e os santos'),
  _Jaculatoria('Todos os santos e santas de Deus, rogai por nós.', 'São José e os santos'),
  // Para momentos específicos
  _Jaculatoria('Senhor, Vós sois a minha força e o meu refúgio.', 'nos momentos de medo'),
  _Jaculatoria('Espírito Santo, iluminai-me e conduzi-me.', 'na incerteza'),
  _Jaculatoria('Jesus, uno meu sofrimento à Vossa Santa Cruz.', 'no sofrimento'),
  _Jaculatoria('Maria Santíssima, ajudai-me a permanecer fiel.', 'na tentação'),
  _Jaculatoria('Senhor, permanecei comigo.', 'na tristeza'),
  _Jaculatoria('Graças e louvores se deem a todo momento ao Santíssimo e Diviníssimo Sacramento.', 'na gratidão'),
  _Jaculatoria('Senhor, seja feita a Vossa vontade, e não a minha.', 'antes de uma decisão'),
  _Jaculatoria('Jesus, atraí-me novamente para Vós.', 'quando me afasto de Deus'),
  _Jaculatoria('Jesus, Maria e José, entrego-Vos o meu coração.', 'antes de dormir'),
  _Jaculatoria('Senhor, este dia é Vosso; conduzi-me segundo a Vossa vontade.', 'ao acordar'),
  _Jaculatoria('Sagrada Família de Nazaré, guardai e santificai a minha família.', 'pela família'),
  _Jaculatoria('Senhor, abençoai aqueles que colocastes em meu caminho.', 'pelos amigos'),
  _Jaculatoria('Senhor, mostrai-me o caminho que preparastes para mim.', 'pela vocação'),
  _Jaculatoria('Jesus, fazei-me santo segundo o Vosso Coração.', 'pela santidade'),
  _Jaculatoria('Senhor, tende misericórdia dos que sofrem.', 'pelos que sofrem'),
  _Jaculatoria('Dai-lhes, Senhor, o descanso eterno, e brilhe para elas a Vossa luz.', 'pelas almas do purgatório'),
  _Jaculatoria('Senhor, fazei de nós instrumentos do Vosso amor.', 'para o grupo'),
  _Jaculatoria('Meu Deus, eu Vos amo!', 'espiritualidade de Santa Teresinha'),
];
