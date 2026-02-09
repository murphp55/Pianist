import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/practice_result.dart';
import 'models/practice_task.dart';
import 'models/practice_plan.dart';
import 'viewmodels/app_state.dart';
import 'widgets/fingering_diagram.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PianistApp());
}

class PianistApp extends StatelessWidget {
  const PianistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Pianist',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Georgia',
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF1F6E54),
            onPrimary: Color(0xFFF8F5EF),
            secondary: Color(0xFFDE6B35),
            onSecondary: Color(0xFFF8F5EF),
            error: Color(0xFFB3261E),
            onError: Color(0xFFF8F5EF),
            surface: Color(0xFFF6F1E8),
            onSurface: Color(0xFF1B1B1B),
          ),
          scaffoldBackgroundColor: const Color(0xFFF6F1E8),
          textTheme: ThemeData.light().textTheme.copyWith(
                headlineSmall: const TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                titleMedium: const TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w600,
                ),
                bodyMedium: const TextStyle(
                  fontFamily: 'Trebuchet MS',
                  height: 1.3,
                ),
              ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF6F1E8),
            foregroundColor: Color(0xFF1B1B1B),
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFFFFFBF6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pianist Practice Lab'),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF6F1E8), Color(0xFFF0E6D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _ConnectionStrip(state: state),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Daily Session'),
                        selected: state.selectedPlanIndex == 0,
                        onSelected: (_) => state.selectPlan(0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Per-Key Extras'),
                        selected: state.selectedPlanIndex == 1,
                        onSelected: (_) => state.selectPlan(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 980;
                        final planPanel =
                            _PlanPanel(state: state, plan: state.currentPlan);
                        final taskPanel = _TaskPanel(state: state);

                        return isWide
                            ? Row(
                                children: [
                                  Expanded(flex: 3, child: planPanel),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 5, child: taskPanel),
                                ],
                              )
                            : Column(
                                children: [
                                  Expanded(child: planPanel),
                                  const SizedBox(height: 16),
                                  Expanded(child: taskPanel),
                                ],
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionStrip extends StatelessWidget {
  const _ConnectionStrip({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: state.isConnected
                    ? const Color(0xFF1F6E54)
                    : const Color(0xFFB2A89A),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                state.isConnected ? 'MIDI Live' : 'Offline',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DeviceDropdown(state: state),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: state.refreshDevices,
              icon: const Icon(Icons.refresh),
              tooltip: 'Rescan devices',
            ),
            const SizedBox(width: 4),
            _ConnectionButton(state: state),
          ],
        ),
      ),
    );
  }
}

class _DeviceDropdown extends StatelessWidget {
  const _DeviceDropdown({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0D6C5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          isExpanded: true,
          value: state.selectedDevice,
          hint: const Text('Select device'),
          items: state.devices
              .map((device) => DropdownMenuItem(
                    value: device,
                    child: Text(device.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (device) {
            if (device != null) {
              state.selectDevice(device);
            }
          },
        ),
      ),
    );
  }
}

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: state.devices.isEmpty
          ? null
          : state.isConnected
              ? state.disconnect
              : state.connect,
      icon: Icon(state.isConnected ? Icons.link_off : Icons.link),
      label: Text(state.isConnected ? 'Disconnect' : 'Connect'),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            state.isConnected ? const Color(0xFF2F3B47) : null,
        foregroundColor: state.isConnected ? Colors.white : null,
      ),
    );
  }
}

class _PlanPanel extends StatelessWidget {
  const _PlanPanel({required this.state, required this.plan});

  final AppState state;
  final PracticePlan plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                      state.selectedPlanIndex == 0
                          ? 'Daily Session'
                          : 'Per-Key Extras',
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                Text(
                  '${plan.sections.fold<int>(0, (sum, section) => sum + section.tasks.length)} tasks',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: const Color(0xFF6E6254)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final section in plan.sections) ...[
                    _SectionHeader(section.title, section.tasks.length),
                    for (final task in section.tasks)
                      _TaskTile(
                        task: task,
                        isSelected: task.id == state.selectedTask.id,
                        result: state.progress.resultFor(task.id),
                        onTap: () => state.selectTask(task),
                      ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.count);

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child:
                Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE0D6C5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('$count',
                style: Theme.of(context).textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.isSelected,
    required this.result,
    required this.onTap,
  });

  final PracticeTask task;
  final bool isSelected;
  final PracticeResult? result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final verdict = result?.verdict;
    final badgeColor = verdict == TaskVerdict.pass
        ? const Color(0xFF1F6E54)
        : verdict == TaskVerdict.completed
            ? const Color(0xFF2F3B47)
            : verdict == TaskVerdict.needsWork
                ? const Color(0xFFDE6B35)
                : const Color(0xFFB2A89A);
    final badgeLabel = verdict == TaskVerdict.pass
        ? 'Pass'
        : verdict == TaskVerdict.completed
            ? 'Done'
            : verdict == TaskVerdict.needsWork
                ? 'Review'
                : 'New';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECE0CF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? const Color(0xFFDE6B35)
                  : const Color(0xFFE0D6C5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeLabel,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskPanel extends StatelessWidget {
  const _TaskPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final task = state.selectedTask;
    final totalNotes = task.expectedNotes.length;
    final progress = totalNotes == 0 ? 0.0 : state.expectedIndex / totalNotes;
    final step =
        (state.expectedIndex + 1).clamp(1, totalNotes == 0 ? 1 : totalNotes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(task.title,
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: state.isRunning
                        ? const Color(0xFF1F6E54)
                        : const Color(0xFFB2A89A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    state.isRunning ? 'In Session' : 'Idle',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(task.description),
            const SizedBox(height: 16),
            Row(
              children: [
                _ActionButton(
                  label: state.isRunning ? 'Restart' : 'Start',
                  icon: Icons.play_arrow,
                  onPressed: state.start,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Reset',
                  icon: Icons.replay,
                  onPressed: state.reset,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Complete',
                  icon: Icons.check,
                  onPressed: state.complete,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Fingering Diagram',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6EC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0D6C5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 220,
                    child: FingeringDiagram(
                      notes: task.expectedNotes,
                      highlightIndex: task.expectedNotes.isEmpty
                          ? 0
                          : state.expectedIndex
                              .clamp(0, task.expectedNotes.length - 1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Correct: ${state.correctCount} / ${task.expectedNotes.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _ProgressPanel(progress: progress, step: step, total: totalNotes),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _InfoChip(
                  label: 'Tempo',
                  value: '${task.tempoBpm} BPM',
                ),
                _InfoChip(
                  label: 'Metronome',
                  value: task.metronomeRequired ? 'On' : 'Off',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FeedbackPanel(state: state),
            const SizedBox(height: 12),
            _DebugPanel(state: state),
          ],
        ),
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.progress,
    required this.step,
    required this.total,
  });

  final double progress;
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Progress',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Text(
              'Step $step of ${total == 0 ? 1 : total}',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: const Color(0xFF6E6254)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 10,
          backgroundColor: const Color(0xFFE0D6C5),
        ),
      ],
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF6EC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Feedback',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FeedbackTile(
                    label: 'Expected',
                    value: state.expectedNote,
                    color: const Color(0xFF2F3B47),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FeedbackTile(
                    label: 'Last Note',
                    value: state.lastNote,
                    color: state.lastWasCorrect
                        ? const Color(0xFF1F6E54)
                        : const Color(0xFFDE6B35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  const _FeedbackTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D6C5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF6E6254),
                  )),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: const Color(0xFF1F6E54),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D6C5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF6E6254),
                  )),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF1B1B1B),
                ),
          ),
        ],
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Debug Tools',
          style: Theme.of(context).textTheme.titleSmall),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: state.simulateNote,
            icon: const Icon(Icons.music_note),
            label: const Text('Simulate Note'),
          ),
        ),
      ],
    );
  }
}
