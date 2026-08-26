/// Texto livre do exame noturno de consciência.
class Reflection {
  const Reflection({
    required this.id,
    required this.date,
    required this.text,
  });

  final String id;
  final DateTime date;
  final String text;

  Reflection copyWith({String? id, DateTime? date, String? text}) {
    return Reflection(
      id: id ?? this.id,
      date: date ?? this.date,
      text: text ?? this.text,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Reflection && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
