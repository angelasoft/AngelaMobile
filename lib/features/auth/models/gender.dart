enum Gender {
  male,
  female;

  String get label => switch (this) {
        Gender.male => '남성',
        Gender.female => '여성',
      };
}
