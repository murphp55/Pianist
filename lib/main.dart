import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/key_signature.dart';
import 'models/practice_result.dart';
import 'models/practice_task.dart';
import 'models/practice_plan.dart';
import 'viewmodels/app_state.dart';
import 'widgets/fingering_diagram.dart';
import 'widgets/metronome_indicator.dart';

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
            title: Row(
              children: [
                const Text('Pianist'),
                const SizedBox(width: 16),
                // Compact connection status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.isConnected
                        ? const Color(0xFF1F6E54)
                        : const Color(0xFFB2A89A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.isConnected ? Icons.circle : Icons.circle_outlined,
                        size: 10,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isConnected ? 'MIDI Connected' : 'MIDI Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // MIDI connection menu button
              IconButton(
                icon: const Icon(Icons.settings_input_composite),
                tooltip: 'MIDI Settings',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _MidiDialog(state: state),
                  );
                },
              ),
              // Plan selector
              PopupMenuButton<int>(
                icon: const Icon(Icons.library_music),
                tooltip: 'Select Practice Plan',
                onSelected: (index) => state.selectPlan(index),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 0,
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 18,
                          color: state.selectedPlanIndex == 0
                              ? const Color(0xFF1F6E54)
                              : Colors.transparent,
                        ),
                        const SizedBox(width: 8),
                        const Text('Daily Session'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 18,
                          color: state.selectedPlanIndex == 1
                              ? const Color(0xFF1F6E54)
                              : Colors.transparent,
                        ),
                        const SizedBox(width: 8),
                        const Text('Per-Key Extras'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isWide = width > 800;
                  final planPanel =
                      _SimplifiedPlanPanel(state: state, plan: state.currentPlan);
                  final diagramPanel = _DiagramFocusedPanel(state: state);

                  if (isWide) {
                    // Wide layout: task list left, diagram/exercise right (prioritized)
                    return Row(
                      children: [
                        Expanded(flex: 2, child: planPanel),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: diagramPanel),
                      ],
                    );
                  } else {
                    // Narrow layout: stacked
                    return Column(
                      children: [
                        Expanded(flex: 2, child: planPanel),
                        const SizedBox(height: 12),
                        Expanded(flex: 5, child: diagramPanel),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MidiDialog extends StatelessWidget {
  const _MidiDialog({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings_input_composite, color: Color(0xFF2F3B47)),
          SizedBox(width: 12),
          Text('MIDI Settings'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: state.isConnected
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF6EC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: state.isConnected
                      ? const Color(0xFF1F6E54)
                      : const Color(0xFFDE6B35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isConnected ? Icons.check_circle : Icons.info_outline,
                    color: state.isConnected
                        ? const Color(0xFF1F6E54)
                        : const Color(0xFFDE6B35),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    state.isConnected
                        ? 'Connected to ${state.selectedDevice?.name ?? "device"}'
                        : 'Not connected',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'MIDI Device',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _DeviceDropdown(state: state),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.refreshDevices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.devices.isEmpty
                        ? null
                        : state.isConnected
                            ? state.disconnect
                            : state.connect,
                    icon: Icon(state.isConnected ? Icons.link_off : Icons.link),
                    label: Text(state.isConnected ? 'Disconnect' : 'Connect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          state.isConnected ? const Color(0xFFDE6B35) : null,
                      foregroundColor: state.isConnected ? Colors.white : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DeviceDropdown extends StatelessWidget {
  const _DeviceDropdown({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    // Empty state when no devices found
    if (state.devices.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6EC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDE6B35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFDE6B35), size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No MIDI devices found. Connect a keyboard and click refresh.',
                style: TextStyle(fontSize: 12, color: Color(0xFF1B1B1B)),
              ),
            ),
          ],
        ),
      );
    }

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

class _SimplifiedPlanPanel extends StatelessWidget {
  const _SimplifiedPlanPanel({required this.state, required this.plan});

  final AppState state;
  final PracticePlan plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key selector dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F1E8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB2A89A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note, size: 18, color: Color(0xFF1F6E54)),
                  const SizedBox(width: 8),
                  const Text(
                    'Key:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2F3B47),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<KeySignature>(
                      value: state.selectedKey,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F6E54),
                        fontWeight: FontWeight.bold,
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1F6E54)),
                      onChanged: (key) {
                        if (key != null) state.setKey(key);
                      },
                      items: KeySignature.allMajorKeys.map((key) {
                        return DropdownMenuItem<KeySignature>(
                          value: key,
                          child: Text(key.name),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.list_alt, size: 20, color: Color(0xFF2F3B47)),
                const SizedBox(width: 8),
                Text(
                  'Practice Tasks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: plan.sections.expand((section) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        section.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: const Color(0xFF6E6254),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    ...section.tasks.map((task) {
                      final result = state.progress.results[task.id];
                      final isSelected = state.selectedTask.id == task.id;
                      return _CompactTaskTile(
                        task: task,
                        isSelected: isSelected,
                        result: result,
                        onTap: () => state.selectTask(task),
                      );
                    }),
                  ];
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactTaskTile extends StatelessWidget {
  const _CompactTaskTile({
    required this.task,
    required this.isSelected,
    required this.result,
    required this.onTap,
  });

  final PracticeTask task;
  final bool isSelected;
  final PracticeResult? result;
  final VoidCallback onTap;

  int _getDifficulty() {
    final noteCount = task.expectedNotes.length;
    final tempo = task.tempoBpm;
    if (tempo >= 100 || noteCount >= 30) return 3;
    if (tempo >= 80 || noteCount >= 20) return 2;
    return 1;
  }

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
    final difficulty = _getDifficulty();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECE0CF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFDE6B35)
                : const Color(0xFFE0D6C5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Difficulty stars
                      ...List.generate(
                        3,
                        (index) => Icon(
                          index < difficulty ? Icons.star : Icons.star_border,
                          size: 12,
                          color: const Color(0xFFDE6B35),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${task.tempoBpm} BPM',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagramFocusedPanel extends StatelessWidget {
  const _DiagramFocusedPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final task = state.selectedTask;
    final totalNotes = task.expectedNotes.length;
    final progress = totalNotes == 0 ? 0.0 : state.expectedIndex / totalNotes;
    final step =
        (state.expectedIndex + 1).clamp(1, totalNotes == 0 ? 1 : totalNotes);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task header with title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.isRunning ? Icons.play_circle : Icons.pause_circle,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isRunning ? 'In Session' : 'Idle',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(task.description),
            const SizedBox(height: 16),
            // Action buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionButton(
                  label: state.isRunning ? 'Restart' : 'Start',
                  icon: Icons.play_arrow,
                  onPressed: state.isConnected ? state.start : null,
                  tooltip: state.isConnected
                      ? (state.isRunning
                          ? 'Restart practice from beginning'
                          : 'Start practicing this task')
                      : 'Connect MIDI device to start',
                  isPrimary: true,
                ),
                _ActionButton(
                  label: 'Reset',
                  icon: Icons.replay,
                  onPressed: state.isRunning ? state.reset : null,
                  tooltip: 'Stop and reset progress counter',
                  isPrimary: false,
                ),
                _ActionButton(
                  label: 'Complete',
                  icon: Icons.check,
                  onPressed: state.isRunning ? state.complete : null,
                  tooltip: 'Mark task as complete manually',
                  isPrimary: false,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE0D6C5)),
            const SizedBox(height: 12),
            // LARGE FINGERING DIAGRAM (prioritized)
            Row(
              children: [
                const Icon(Icons.piano, size: 20, color: Color(0xFF2F3B47)),
                const SizedBox(width: 8),
                Text(
                  'Fingering Diagram',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6EC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0D6C5)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: FingeringDiagram(
                        notes: task.expectedNotes,
                        highlightIndex: task.expectedNotes.isEmpty
                            ? 0
                            : state.expectedIndex
                                .clamp(0, task.expectedNotes.length - 1),
                        keySignature: state.selectedKey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress: $step / ${totalNotes == 0 ? 1 : totalNotes}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Correct: ${state.correctCount}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: const Color(0xFF1F6E54),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Animated progress bar
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      tween: Tween<double>(begin: 0, end: progress),
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE0D6C5),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF1F6E54),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Compact info row
            Row(
              children: [
                _InfoChip(label: 'Notes', value: '${task.expectedNotes.length}'),
                const SizedBox(width: 12),
                _InfoChip(label: 'Tempo', value: '${task.tempoBpm} BPM'),
                const SizedBox(width: 12),
                _InfoChip(
                  label: 'Metronome',
                  value: task.metronomeRequired ? 'On' : 'Off',
                ),
              ],
            ),
            if (task.metronomeRequired) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                color: const Color(0xFFFFF6EC),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MetronomeIndicator(
                        currentBeat: state.currentBeat,
                        isActive: state.isRunning,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Compact feedback
            _CompactFeedbackPanel(state: state),
          ],
        ),
      ),
    );
  }
}

class _CompactFeedbackPanel extends StatelessWidget {
  const _CompactFeedbackPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0D6C5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.music_note,
                        size: 14, color: Color(0xFF6E6254)),
                    const SizedBox(width: 6),
                    Text('Expected',
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  state.expectedNote,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF2F3B47),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0D6C5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      state.lastWasCorrect ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: state.lastWasCorrect
                          ? const Color(0xFF1F6E54)
                          : const Color(0xFFDE6B35),
                    ),
                    const SizedBox(width: 6),
                    Text('Last Note',
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  state.lastNote,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: state.lastWasCorrect
                            ? const Color(0xFF1F6E54)
                            : const Color(0xFFDE6B35),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor:
              isPrimary ? const Color(0xFF1F6E54) : const Color(0xFF2F3B47),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE0D6C5),
          disabledForegroundColor: const Color(0xFF6E6254),
          elevation: isPrimary ? 2 : 0,
        ),
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

