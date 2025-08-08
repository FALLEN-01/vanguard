import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// The chaotic text editor system that randomly interferes with user input
class ChaosController {
  final TextEditingController textController;
  final Function(String) onTextChanged;
  final Function(TextSelection) onSelectionChanged;
  final Function() onSave;

  Timer? _chaosTimer;
  final Random _random = Random();
  bool _isActive = true;

  // Chaos behaviors weighted by frequency
  final List<ChaosAction> _chaosActions;

  ChaosController({
    required this.textController,
    required this.onTextChanged,
    required this.onSelectionChanged,
    required this.onSave,
  }) : _chaosActions = [
         ChaosAction(ChaosType.cursorDisplacement, weight: 25),
         ChaosAction(ChaosType.randomDeletion, weight: 20),
         ChaosAction(ChaosType.letterSwapping, weight: 15),
         ChaosAction(ChaosType.wordSwapping, weight: 10),
         ChaosAction(ChaosType.punctuationInsert, weight: 20),
         ChaosAction(ChaosType.punctuationDuplicate, weight: 10),
       ];

  /// Start the chaos cycle
  void startChaos() {
    _isActive = true;
    _scheduleNextChaos();
  }

  /// Stop the chaos cycle
  void stopChaos() {
    _isActive = false;
    _chaosTimer?.cancel();
  }

  /// Schedule the next chaotic event
  void _scheduleNextChaos() {
    if (!_isActive) return;

    // Random delay between 8-15 seconds
    final delaySeconds = 8 + _random.nextInt(8);

    _chaosTimer = Timer(Duration(seconds: delaySeconds), () {
      _executeChaos();
      _scheduleNextChaos();
    });
  }

  /// Execute a random chaotic behavior
  void _executeChaos() {
    if (!_isActive || textController.text.isEmpty) return;

    final action = _selectRandomAction();
    _performChaosAction(action.type);
  }

  /// Select a random chaos action based on weights
  ChaosAction _selectRandomAction() {
    final totalWeight = _chaosActions.fold(
      0,
      (sum, action) => sum + action.weight,
    );
    final randomValue = _random.nextInt(totalWeight);

    int currentWeight = 0;
    for (final action in _chaosActions) {
      currentWeight += action.weight;
      if (randomValue < currentWeight) {
        return action;
      }
    }

    return _chaosActions.first; // fallback
  }

  /// Perform the specified chaos action
  void _performChaosAction(ChaosType type) {
    final text = textController.text;
    if (text.isEmpty) return;

    switch (type) {
      case ChaosType.cursorDisplacement:
        _displaceCursor();
        break;
      case ChaosType.randomDeletion:
        _performRandomDeletion();
        break;
      case ChaosType.letterSwapping:
        _swapLetters();
        break;
      case ChaosType.wordSwapping:
        _swapWords();
        break;
      case ChaosType.punctuationInsert:
        _insertRandomPunctuation();
        break;
      case ChaosType.punctuationDuplicate:
        _duplicatePunctuation();
        break;
      case ChaosType.randomIndentation:
        _addRandomIndentation();
        break;
    }
  }

  /// Move cursor to random position
  void _displaceCursor() {
    final text = textController.text;
    if (text.isEmpty) return;

    final newPosition = _random.nextInt(text.length + 1);
    final newSelection = TextSelection.collapsed(offset: newPosition);

    textController.selection = newSelection;
    onSelectionChanged(newSelection);
  }

  /// Delete random character or word
  void _performRandomDeletion() {
    final text = textController.text;
    if (text.isEmpty) return;

    final shouldDeleteWord = _random.nextBool() && text.contains(' ');

    if (shouldDeleteWord) {
      _deleteRandomWord();
    } else {
      _deleteRandomCharacter();
    }
  }

  /// Delete a random character
  void _deleteRandomCharacter() {
    final text = textController.text;
    if (text.isEmpty) return;

    final deleteIndex = _random.nextInt(text.length);
    final newText =
        text.substring(0, deleteIndex) + text.substring(deleteIndex + 1);

    textController.text = newText;
    textController.selection = TextSelection.collapsed(
      offset: deleteIndex.clamp(0, newText.length),
    );
    onTextChanged(newText);
  }

  /// Delete a random word
  void _deleteRandomWord() {
    final text = textController.text;
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= 1) return;

    final wordIndex = _random.nextInt(words.length);
    words.removeAt(wordIndex);

    final newText = words.join(' ');
    textController.text = newText;
    textController.selection = TextSelection.collapsed(offset: newText.length);
    onTextChanged(newText);
  }

  /// Swap two random letters within a word
  void _swapLetters() {
    final text = textController.text;
    final words = text.split(' ');

    // Find a word with at least 2 characters
    final validWords = words.where((word) => word.length >= 2).toList();
    if (validWords.isEmpty) return;

    final word = validWords[_random.nextInt(validWords.length)];
    final wordIndex = words.indexOf(word);

    // Swap two random letters
    final letterIndices = List.generate(word.length, (i) => i);
    letterIndices.shuffle(_random);
    final index1 = letterIndices[0];
    final index2 = letterIndices[1];

    final chars = word.split('');
    final temp = chars[index1];
    chars[index1] = chars[index2];
    chars[index2] = temp;

    words[wordIndex] = chars.join('');
    final newText = words.join(' ');

    textController.text = newText;
    onTextChanged(newText);
  }

  /// Swap two random words
  void _swapWords() {
    final text = textController.text;
    final words = text.split(' ');
    if (words.length < 2) return;

    final indices = List.generate(words.length, (i) => i);
    indices.shuffle(_random);
    final index1 = indices[0];
    final index2 = indices[1];

    final temp = words[index1];
    words[index1] = words[index2];
    words[index2] = temp;

    final newText = words.join(' ');
    textController.text = newText;
    onTextChanged(newText);
  }

  /// Insert random punctuation at random position
  void _insertRandomPunctuation() {
    final text = textController.text;
    if (text.isEmpty) return;

    final punctuation = ['.', ',', '!', '?', ';', ':', '-'];
    final randomPunct = punctuation[_random.nextInt(punctuation.length)];
    final insertIndex = _random.nextInt(text.length + 1);

    final newText =
        text.substring(0, insertIndex) +
        randomPunct +
        text.substring(insertIndex);

    textController.text = newText;
    textController.selection = TextSelection.collapsed(offset: insertIndex + 1);
    onTextChanged(newText);
  }

  /// Duplicate existing punctuation
  void _duplicatePunctuation() {
    final text = textController.text;
    final punctuationRegex = RegExp(r'[.!?,;:]');
    final matches = punctuationRegex.allMatches(text).toList();

    if (matches.isEmpty) return;

    final match = matches[_random.nextInt(matches.length)];
    final punctuation = match.group(0)!;
    final position = match.start;

    final newText =
        text.substring(0, position + 1) +
        punctuation +
        text.substring(position + 1);

    textController.text = newText;
    onTextChanged(newText);
  }

  /// Add random indentation to lines (triggered on save)
  void _addRandomIndentation() {
    final text = textController.text;
    final lines = text.split('\n');

    // Randomly indent 1-3 lines
    final linesToIndent = _random.nextInt(3) + 1;
    final selectedLines = <int>{};

    while (selectedLines.length < linesToIndent &&
        selectedLines.length < lines.length) {
      selectedLines.add(_random.nextInt(lines.length));
    }

    for (final lineIndex in selectedLines) {
      final isTab = _random.nextBool();
      final indentCount = _random.nextInt(4) + 1;
      final indent = isTab ? '\t' * indentCount : '  ' * indentCount;
      lines[lineIndex] = indent + lines[lineIndex];
    }

    final newText = lines.join('\n');
    textController.text = newText;
    onTextChanged(newText);
  }

  /// Handle save action with random indentation
  void handleSave() {
    // 70% chance to add random indentation on save
    if (_random.nextInt(10) < 7) {
      _addRandomIndentation();
    }
    onSave();
  }

  /// Dispose resources
  void dispose() {
    stopChaos();
  }
}

/// Types of chaotic behaviors
enum ChaosType {
  cursorDisplacement,
  randomDeletion,
  letterSwapping,
  wordSwapping,
  punctuationInsert,
  punctuationDuplicate,
  randomIndentation,
}

/// Chaos action with weight for random selection
class ChaosAction {
  final ChaosType type;
  final int weight;

  ChaosAction(this.type, {required this.weight});
}
