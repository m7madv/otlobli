import 'dart:math' as math;

abstract final class AmplitudeVisualizer {
  static const restingLevel = 0.08;

  static double levelFromDbfs(double dbfs) {
    if (!dbfs.isFinite) return restingLevel;

    final safeDbfs = dbfs.clamp(-80.0, 0.0);
    final linearAmplitude = math.pow(10, safeDbfs / 20).toDouble();
    return math.pow(linearAmplitude, 0.45).toDouble().clamp(restingLevel, 1.0);
  }

  static double smooth({required double previous, required double next}) {
    final response = next >= previous ? 0.68 : 0.34;
    return (previous + (next - previous) * response).clamp(restingLevel, 1.0);
  }
}
