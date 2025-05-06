class EvaluationConfig {
  final double spellingPenalty;
  final double punctuationPenalty;
  final double stylisticPenalty;
  final double graphicPenalty;
  final double neighborKeyMultiplier;

  EvaluationConfig({
    this.spellingPenalty = 1.0,
    this.punctuationPenalty = 0.5,
    this.stylisticPenalty = 0.3,
    this.graphicPenalty = 0.2,
    this.neighborKeyMultiplier = 0.5,
  });
}
