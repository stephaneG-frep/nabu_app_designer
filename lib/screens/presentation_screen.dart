import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/project_provider.dart';
import '../widgets/device_preview.dart';

class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _autoPlay = false;
  int _intervalSeconds = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleAutoPlay(int screenCount) {
    setState(() => _autoPlay = !_autoPlay);
    if (_autoPlay) {
      _timer = Timer.periodic(Duration(seconds: _intervalSeconds), (_) {
        if (!mounted) return;
        final next = (_currentIndex + 1) % screenCount;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    } else {
      _timer?.cancel();
    }
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.activeProject;

    if (project == null || project.id != widget.projectId) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = project.screens;
    if (screens.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Présentation')),
        body: const Center(child: Text('Aucun écran.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Présentation', style: TextStyle(fontSize: 14)),
            Text(
              '${_currentIndex + 1} / ${screens.length}  ·  ${screens[_currentIndex].name}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          DropdownButton<int>(
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox.shrink(),
            value: _intervalSeconds,
            items: const [
              DropdownMenuItem(value: 2, child: Text('2s')),
              DropdownMenuItem(value: 3, child: Text('3s')),
              DropdownMenuItem(value: 5, child: Text('5s')),
              DropdownMenuItem(value: 10, child: Text('10s')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _intervalSeconds = v);
              if (_autoPlay) {
                _timer?.cancel();
                _timer = Timer.periodic(Duration(seconds: v), (_) {
                  if (!mounted) return;
                  final next = (_currentIndex + 1) % screens.length;
                  _goTo(next);
                });
              }
            },
          ),
          IconButton(
            tooltip: _autoPlay ? 'Pause' : 'Lecture auto',
            icon: Icon(_autoPlay ? Icons.pause_rounded : Icons.play_arrow_rounded),
            color: Colors.white,
            onPressed: () => _toggleAutoPlay(screens.length),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: screens.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: DevicePreview(
                      screen: screens[index],
                      selectedComponentIds: const [],
                      onSelectComponent: (_) {},
                      onToggleComponentSelection: (_) {},
                      onBackgroundTap: () {},
                      showDeviceFrame: true,
                      selectionMode: false,
                      interactiveMode: true,
                      frameMaxWidth: 360,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  color: Colors.white,
                  onPressed: _currentIndex > 0
                      ? () => _goTo(_currentIndex - 1)
                      : null,
                ),
                const SizedBox(width: 8),
                ...List.generate(screens.length, (i) {
                  final active = i == _currentIndex;
                  return GestureDetector(
                    onTap: () => _goTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: active ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  color: Colors.white,
                  onPressed: _currentIndex < screens.length - 1
                      ? () => _goTo(_currentIndex + 1)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
