import 'package:flutter/material.dart';
import '../models/survey/survey_model.dart';

class QuestionBuilderWidget extends StatefulWidget {
  final List<SurveyQuestion> questions;
  final Function(List<SurveyQuestion>) onQuestionsChanged;

  const QuestionBuilderWidget({
    super.key,
    required this.questions,
    required this.onQuestionsChanged,
  });

  @override
  State<QuestionBuilderWidget> createState() => _QuestionBuilderWidgetState();
}

class _QuestionBuilderWidgetState extends State<QuestionBuilderWidget> {
  List<SurveyQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.questions);
  }
  void _addQuestion(QuestionType type) {
    final newQuestion = SurveyQuestion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      surveyId: '0', // Will be set when creating the survey
      questionText: '',
      questionType: type,
      orderIndex: _questions.length,
      isRequired: false,
      options: type == QuestionType.multipleChoiceSingle || 
               type == QuestionType.multipleChoiceMultiple 
               ? [
                   QuestionOption(
                     id: '1',
                     questionId: DateTime.now().millisecondsSinceEpoch.toString(),
                     optionText: 'Option 1',
                     orderIndex: 0,
                   ),
                   QuestionOption(
                     id: '2',
                     questionId: DateTime.now().millisecondsSinceEpoch.toString(),
                     optionText: 'Option 2',
                     orderIndex: 1,
                   )
                 ]
               : [],
    );
    
    setState(() {
      _questions.add(newQuestion);
    });
    widget.onQuestionsChanged(_questions);
  }

  void _updateQuestion(int index, SurveyQuestion updatedQuestion) {
    setState(() {
      _questions[index] = updatedQuestion;
    });
    widget.onQuestionsChanged(_questions);
  }  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
    widget.onQuestionsChanged(_questions);
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final question = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, question);
      
      // Update order indices
      for (int i = 0; i < _questions.length; i++) {
        _questions[i] = _questions[i].copyWith(orderIndex: i);
      }
    });
    widget.onQuestionsChanged(_questions);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Questions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),            PopupMenuButton<QuestionType>(
              tooltip: 'Add Question',
              onSelected: _addQuestion,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: QuestionType.multipleChoiceSingle,
                  child: Row(
                    children: [
                      Icon(Icons.radio_button_checked),
                      SizedBox(width: 8),
                      Text('Multiple Choice (Single)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: QuestionType.multipleChoiceMultiple,
                  child: Row(
                    children: [
                      Icon(Icons.check_box),
                      SizedBox(width: 8),
                      Text('Multiple Choice (Multiple)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: QuestionType.openText,
                  child: Row(
                    children: [
                      Icon(Icons.text_fields),
                      SizedBox(width: 8),
                      Text('Open Text'),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Add Question',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_questions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No questions added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Click "Add Question" to start building your survey',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: _reorderQuestions,
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              return Padding(
                key: ValueKey(_questions[index].id),
                padding: const EdgeInsets.only(bottom: 16),
                child: QuestionCard(
                  question: _questions[index],
                  index: index,
                  onUpdate: (updatedQuestion) => _updateQuestion(index, updatedQuestion),
                  onRemove: () => _removeQuestion(index),
                ),
              );
            },
          ),
      ],
    );
  }
}

class QuestionCard extends StatefulWidget {
  final SurveyQuestion question;
  final int index;
  final Function(SurveyQuestion) onUpdate;
  final VoidCallback onRemove;

  const QuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  late TextEditingController _textController;
  late List<TextEditingController> _optionControllers;
  late SurveyQuestion _currentQuestion;

  @override
  void initState() {
    super.initState();
    _currentQuestion = widget.question;
    _textController = TextEditingController(text: _currentQuestion.questionText);
    _initializeOptionControllers();
  }

  void _initializeOptionControllers() {
    _optionControllers = [];
    for (var option in _currentQuestion.options) {
      _optionControllers.add(TextEditingController(text: option.optionText));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateQuestion() {    final updatedOptions = _optionControllers.asMap().entries.map((entry) {
      return QuestionOption(
        id: (entry.key + 1).toString(),
        questionId: _currentQuestion.id,
        optionText: entry.value.text,
        orderIndex: entry.key,
      );
    }).toList();

    final updatedQuestion = _currentQuestion.copyWith(
      questionText: _textController.text,
      options: updatedOptions,
    );
    
    setState(() {
      _currentQuestion = updatedQuestion;
    });
    widget.onUpdate(updatedQuestion);
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController(text: 'Option ${_optionControllers.length + 1}'));
    });
    _updateQuestion();
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
      _updateQuestion();
    }
  }

  void _toggleRequired() {
    setState(() {
      _currentQuestion = _currentQuestion.copyWith(isRequired: !_currentQuestion.isRequired);
    });
    widget.onUpdate(_currentQuestion);
  }
  String _getQuestionTypeIcon() {
    switch (_currentQuestion.questionType) {
      case QuestionType.multipleChoiceSingle:
        return '○';
      case QuestionType.multipleChoiceMultiple:
        return '☐';
      case QuestionType.openText:
        return '📝';
    }
  }
  String _getQuestionTypeName() {
    switch (_currentQuestion.questionType) {
      case QuestionType.multipleChoiceSingle:
        return 'Multiple Choice (Single)';
      case QuestionType.multipleChoiceMultiple:
        return 'Multiple Choice (Multiple)';
      case QuestionType.openText:
        return 'Open Text';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getQuestionTypeIcon(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getQuestionTypeName(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.drag_handle),
                  onPressed: null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Question ${widget.index + 1}',
                hintText: 'Enter your question here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: null,
              onChanged: (_) => _updateQuestion(),
            ),
            const SizedBox(height: 12),            if (_currentQuestion.questionType == QuestionType.multipleChoiceSingle ||
                _currentQuestion.questionType == QuestionType.multipleChoiceMultiple)
              _buildOptionsSection(),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _currentQuestion.isRequired,
                  onChanged: (_) => _toggleRequired(),
                ),
                const Text('Required'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Options',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Option'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_optionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  _currentQuestion.questionType == QuestionType.multipleChoiceSingle
                      ? Icons.radio_button_unchecked
                      : Icons.check_box_outline_blank,
                  size: 20,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(
                      hintText: 'Option ${index + 1}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) => _updateQuestion(),
                  ),
                ),
                if (_optionControllers.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => _removeOption(index),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
