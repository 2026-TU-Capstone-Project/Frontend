enum FitType {
  slim,
  regular,
  oversize;

  String get label {
    switch (this) {
      case FitType.slim:
        return '슬림핏';
      case FitType.regular:
        return '레귤러핏';
      case FitType.oversize:
        return '오버핏';
    }
  }

  String get description {
    switch (this) {
      case FitType.slim:
        return '몸에 딱 맞는';
      case FitType.regular:
        return '적당한 여유';
      case FitType.oversize:
        return '넉넉한 핏';
    }
  }
}
