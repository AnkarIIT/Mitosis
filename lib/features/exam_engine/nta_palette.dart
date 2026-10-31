import 'package:flutter/material.dart';

/// NTA exam chrome colours.
///
/// The paper screen is a deliberate exception to the app's Calm Academic
/// palette: NTA's CBT is blue-and-white, dense and utilitarian, and candidates
/// who have practised on the real interface should recognise it instantly.
/// The rest of the app stays teal.
///
/// Green and orange are pulled a shade darker than the pixels of the reference
/// screenshot so that white bold labels clear WCAG's 3:1 large-text threshold.
abstract final class NtaExamColors {
  /// Top strip and footer bar.
  static const Color navy = Color(0xFF1B3A6B);

  static const Color accent = Color(0xFF1565C0);
  static const Color page = Color(0xFFF2F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD5DCE6);
  static const Color hairline = Color(0xFFBFC6D0);
  static const Color text = Color(0xFF17202A);
  static const Color textMuted = Color(0xFF5B6777);

  /// Control-row buttons.
  static const Color saveGreen = Color(0xFF43A047);
  static const Color saveOrange = Color(0xFFE07B00);
  static const Color markBlue = Color(0xFF1976D2);
  static const Color chrome = Color(0xFFEDEDED);
  static const Color chromeBorder = Color(0xFFB9BEC7);

  /// Candidate strip values — the same hues as the controls, named for where
  /// they are read so a colour change stays in one place.
  static const Color valueOrange = saveOrange;
  static const Color valueBlue = accent;

  static const Color danger = Color(0xFFC62828);
  static const Color green = Color(0xFF2E7D32);
  static const Color purple = Color(0xFF6A1B9A);
}

/// The five states an NTA CBT question palette distinguishes.
///
/// NTA's own legend (and every candidate who has sat a real paper) expects
/// exactly these five, and they are not interchangeable: "not answered" means
/// *visited but skipped*, which is different from "not visited".
enum NtaPaletteState {
  notVisited,
  notAnswered,
  answered,
  marked,
  answeredMarked,
}

NtaPaletteState ntaPaletteStateFor({
  required bool answered,
  required bool marked,
  required bool visited,
}) {
  if (answered && marked) return NtaPaletteState.answeredMarked;
  if (answered) return NtaPaletteState.answered;
  if (marked) return NtaPaletteState.marked;
  if (visited) return NtaPaletteState.notAnswered;
  return NtaPaletteState.notVisited;
}

/// Fixed palette fills.
///
/// Deliberately not theme-adaptive: the paper screen is always the NTA light
/// interface. Grey = not visited, orange = not answered, green = answered,
/// purple = marked for review, purple + tick = answered and marked.
abstract final class NtaPaletteColors {
  static const Color answered = NtaExamColors.green;
  static const Color notAnswered = Color(0xFFE8590C);
  static const Color marked = NtaExamColors.purple;
  static const Color answeredMarked = NtaExamColors.purple;
  static const Color notVisited = Color(0xFFE0E0E0);

  static Color fill(NtaPaletteState state) {
    switch (state) {
      case NtaPaletteState.answered:
        return answered;
      case NtaPaletteState.notAnswered:
        return notAnswered;
      case NtaPaletteState.marked:
      case NtaPaletteState.answeredMarked:
        return marked;
      case NtaPaletteState.notVisited:
        return notVisited;
    }
  }

  static Color foreground(NtaPaletteState state) {
    return state == NtaPaletteState.notVisited
        ? const Color(0xFF333333)
        : Colors.white;
  }

  static String label(NtaPaletteState state) {
    switch (state) {
      case NtaPaletteState.answered:
        return 'Answered';
      case NtaPaletteState.notAnswered:
        return 'Not Answered';
      case NtaPaletteState.marked:
        return 'Marked for Review';
      case NtaPaletteState.answeredMarked:
        return 'Answered & Marked for Review';
      case NtaPaletteState.notVisited:
        return 'Not Visited';
    }
  }
}

/// Answer bookkeeping for one scope of questions (a section, a block, or the
/// whole paper). Kept separate from the widgets so the submit dialog and the
/// palette legend can never disagree.
class NtaCountSummary {
  final int total;
  final int answered;
  final int notAnswered;
  final int marked;
  final int answeredMarked;
  final int notVisited;

  const NtaCountSummary({
    required this.total,
    required this.answered,
    required this.notAnswered,
    required this.marked,
    required this.answeredMarked,
    required this.notVisited,
  });

  factory NtaCountSummary.from({
    required Iterable<int> indices,
    required Map<int, String> answers,
    required Set<int> marked,
    required Set<int> visited,
  }) {
    var answered = 0;
    var notAnswered = 0;
    var markedCount = 0;
    var answeredMarked = 0;
    var notVisited = 0;
    var total = 0;
    for (final i in indices) {
      total++;
      final isAnswered = answers.containsKey(i);
      final isMarked = marked.contains(i);
      if (isAnswered && isMarked) {
        answeredMarked++;
      } else if (isAnswered) {
        answered++;
      } else if (isMarked) {
        markedCount++;
      } else if (visited.contains(i)) {
        notAnswered++;
      } else {
        notVisited++;
      }
    }
    return NtaCountSummary(
      total: total,
      answered: answered,
      notAnswered: notAnswered,
      marked: markedCount,
      answeredMarked: answeredMarked,
      notVisited: notVisited,
    );
  }

  int get attempted => answered + answeredMarked;
  int get remaining => total - attempted;

  int countOf(NtaPaletteState state) {
    switch (state) {
      case NtaPaletteState.answered:
        return answered;
      case NtaPaletteState.notAnswered:
        return notAnswered;
      case NtaPaletteState.marked:
        return marked;
      case NtaPaletteState.answeredMarked:
        return answeredMarked;
      case NtaPaletteState.notVisited:
        return notVisited;
    }
  }
}

/// One section/block group in the palette.
class NtaPaletteSection {
  final String name;
  final List<int> indices;

  /// True when the candidate may not jump into this group yet (e.g. NEET
  /// Section B before Section A is submitted).
  final bool locked;

  const NtaPaletteSection({
    required this.name,
    required this.indices,
    this.locked = false,
  });
}

/// One line of the NTA legend: the shape-coded count chip, its label, and an
/// optional note.
///
/// The palette legend and the submit dialog both show these five states. Each
/// used to format its own label and colour, and they drifted — the palette said
/// "Answered & Marked" while the dialog said "Answered & Marked for Review".
/// Both now render this row, so the wording, the colour and the count come from
/// one place.
class NtaCountRow extends StatelessWidget {
  const NtaCountRow({
    super.key,
    required this.state,
    required this.count,
    this.note,
    this.fontSize = 11,
  });

  final NtaPaletteState state;
  final int count;
  final String? note;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CountChip(state: state, count: count),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                NtaPaletteColors.label(state),
                maxLines: 2,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: NtaExamColors.text,
                ),
              ),
              if (note != null)
                Text(
                  note!,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 8.5,
                    height: 1.2,
                    color: NtaExamColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The right-hand palette: dotted legend box with live counts, question grid,
/// submit and the Question Paper / Instructions actions. Used inline on wide
/// layouts and inside a bottom sheet on phones, so it is built once.
class NtaQuestionPalette extends StatelessWidget {
  const NtaQuestionPalette({
    super.key,
    required this.sections,
    required this.answers,
    required this.marked,
    required this.visited,
    required this.currentIndex,
    required this.onJump,
    required this.onSubmit,
    this.onShowPaper,
    this.onShowInstructions,
    this.showHeader = true,
    this.lockedMessage,
  });

  final List<NtaPaletteSection> sections;
  final Map<int, String> answers;
  final Set<int> marked;
  final Set<int> visited;
  final int currentIndex;
  final ValueChanged<int> onJump;
  final VoidCallback onSubmit;
  final VoidCallback? onShowPaper;
  final VoidCallback? onShowInstructions;
  final bool showHeader;
  final String? lockedMessage;

  List<int> get _allIndices => [
    for (final section in sections) ...section.indices,
  ];

  NtaCountSummary get _summary => NtaCountSummary.from(
    indices: _allIndices,
    answers: answers,
    marked: marked,
    visited: visited,
  );

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    return ColoredBox(
      color: NtaExamColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHeader)
            Container(
              color: NtaExamColors.navy,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.grid_view_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Question Palette',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${summary.attempted}/${summary.total}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: _buildLegend(context, summary),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final section in sections) ...[
                    if (sections.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                section.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: NtaExamColors.textMuted,
                                ),
                              ),
                            ),
                            if (section.locked)
                              const Icon(
                                Icons.lock_outline,
                                size: 12,
                                color: NtaExamColors.textMuted,
                              ),
                          ],
                        ),
                      ),
                    _buildGrid(context, section),
                  ],
                ],
              ),
            ),
          ),
          Container(
            color: NtaExamColors.surface,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 42,
                  child: FilledButton(
                    onPressed: onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: NtaExamColors.saveGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Submit Test'),
                  ),
                ),
                if (onShowPaper != null || onShowInstructions != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (onShowPaper != null)
                        Expanded(
                          child: _FooterAction(
                            label: 'Question Paper',
                            onPressed: onShowPaper!,
                          ),
                        ),
                      if (onShowPaper != null && onShowInstructions != null)
                        const SizedBox(width: 6),
                      if (onShowInstructions != null)
                        Expanded(
                          child: _FooterAction(
                            label: 'Instructions',
                            onPressed: onShowInstructions!,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// NTA's dotted legend box: count in a shape-coded chip, label to the right,
  /// two per row with "Answered & Marked" spanning the bottom row.
  Widget _buildLegend(BuildContext context, NtaCountSummary summary) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: const Color(0xFF9AA0A6)),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 10) / 2;
            Widget cell(NtaPaletteState state, {String? note}) {
              return SizedBox(
                width: itemWidth,
                child: NtaCountRow(
                  state: state,
                  count: summary.countOf(state),
                  note: note,
                ),
              );
            }

            return Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                cell(NtaPaletteState.notVisited),
                cell(NtaPaletteState.notAnswered),
                cell(NtaPaletteState.answered),
                cell(NtaPaletteState.marked),
                SizedBox(
                  width: constraints.maxWidth,
                  child: cell(
                    NtaPaletteState.answeredMarked,
                    note: 'will be considered for evaluation',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, NtaPaletteSection section) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 5.0;
        const minChip = 40.0;
        final columns = ((constraints.maxWidth + spacing) / (minChip + spacing))
            .floor()
            .clamp(4, 8);
        final chipWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final index in section.indices)
              SizedBox(
                width: chipWidth,
                height: 38,
                child: _PaletteChip(
                  index: index,
                  state: ntaPaletteStateFor(
                    answered: answers.containsKey(index),
                    marked: marked.contains(index),
                    visited: visited.contains(index),
                  ),
                  isCurrent: index == currentIndex,
                  enabled: !section.locked,
                  onTap: () {
                    if (section.locked) {
                      if (lockedMessage != null) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(lockedMessage!)),
                          );
                      }
                      return;
                    }
                    onJump(index);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Count chip shapes: rounded rectangle for not visited, right-pointing pentagon
/// for answered / not answered, circle for the two marked states — the same
/// shapes NTA's legend has used since the first CBT.
class _CountChip extends StatelessWidget {
  const _CountChip({required this.state, required this.count});

  final NtaPaletteState state;
  final int count;

  @override
  Widget build(BuildContext context) {
    final fill = NtaPaletteColors.fill(state);
    final fg = NtaPaletteColors.foreground(state);
    final number = Text(
      '$count',
      key: ValueKey('nta-count-${state.name}'),
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: fg,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    if (state == NtaPaletteState.marked ||
        state == NtaPaletteState.answeredMarked) {
      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: number,
      );
    }

    if (state == NtaPaletteState.notAnswered ||
        state == NtaPaletteState.answered) {
      return Container(
        width: 32,
        height: 26,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 6, right: 9),
        decoration: ShapeDecoration(shape: _PointyShape(fill: fill)),
        child: number,
      );
    }

    return Container(
      width: 32,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFBFC3C7)),
      ),
      child: number,
    );
  }
}

class _PointyShape extends ShapeBorder {
  const _PointyShape({required this.fill, this.tip = 9});

  final Color fill;
  final double tip;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right - tip, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.right - tip, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      getOuterPath(rect),
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
  }

  @override
  ShapeBorder scale(double t) => _PointyShape(fill: fill, tip: tip * t);
}

/// Dotted rectangle, as NTA draws its legend box.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  static const double _dash = 4;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final rect = Path()..addRect(Offset.zero & size);
    final dashed = Path();
    for (final metric in rect.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashed.addPath(
          metric.extractPath(distance, distance + _dash),
          Offset.zero,
        );
        distance += _dash + _gap;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          foregroundColor: NtaExamColors.accent,
          side: const BorderSide(color: NtaExamColors.chromeBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    required this.index,
    required this.state,
    required this.isCurrent,
    required this.enabled,
    required this.onTap,
  });

  final int index;
  final NtaPaletteState state;
  final bool isCurrent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = NtaPaletteColors.fill(state);
    final foreground = NtaPaletteColors.foreground(state);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isCurrent
                        ? NtaExamColors.navy
                        : Colors.white.withValues(alpha: 0.9),
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (state == NtaPaletteState.answeredMarked)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 8,
                      color: NtaPaletteColors.answered,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
