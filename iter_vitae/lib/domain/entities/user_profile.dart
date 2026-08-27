/// Perfil pessoal do dirigido (dados complementares além da conta).
class UserProfile {
  const UserProfile({
    this.nome,
    this.telefone,
    this.paroquia,
  });

  /// Nome completo do usuário.
  final String? nome;

  /// Telefone de contato (texto livre).
  final String? telefone;

  /// Paróquia / comunidade do usuário (opcional).
  final String? paroquia;

  UserProfile copyWith({
    String? nome,
    String? telefone,
    String? paroquia,
  }) {
    return UserProfile(
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      paroquia: paroquia ?? this.paroquia,
    );
  }
}
