import 'package:flutter/material.dart';
import 'lib/core/services/survey_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test survey response submission
  final surveyService = SurveyService();
  
  // Replace with actual survey ID from your app
  const testSurveyId = 'your-survey-id-here';
  const testUserId = 'test-parent-user-id';
  
  try {
    // First, let's get the survey to see the question structure
    print('Fetching survey...');
    final survey = await surveyService.fetchSurveyById(testSurveyId);
    
    if (survey == null) {
      print('Survey not found!');
      return;
    }
    
    print('Survey found: ${survey.title}');
    print('Questions count: ${survey.questions.length}');
    
    // Print question details
    for (int i = 0; i < survey.questions.length; i++) {
      final question = survey.questions[i];
      print('Question $i:');
      print('  ID: ${question.id}');
      print('  Text: ${question.questionText}');
      print('  Type: ${question.questionType}');
      print('  Options: ${question.options.map((o) => o.optionText).toList()}');
    }
    
    // Create test answers based on the actual questions
    final answers = <String, dynamic>{};
    
    for (final question in survey.questions) {
      switch (question.questionType) {
        case QuestionType.multipleChoiceSingle:
          if (question.options.isNotEmpty) {
            answers[question.id] = question.options.first.optionText;
          }
          break;
        case QuestionType.multipleChoiceMultiple:
          if (question.options.isNotEmpty) {
            answers[question.id] = [question.options.first.optionText];
          }
          break;
        case QuestionType.openText:
          answers[question.id] = 'Test response for question: ${question.questionText}';
          break;
      }
    }
    
    print('\nSubmitting test response with answers:');
    answers.forEach((questionId, answer) {
      print('  Question $questionId: $answer');
    });
    
    // Submit the response
    final success = await surveyService.submitSurveyResponse(
      surveyId: testSurveyId,
      userId: testUserId,
      answers: answers,
    );
    
    if (success) {
      print('\nResponse submitted successfully!');
      
      // Now fetch responses to verify
      print('Fetching responses...');
      final responses = await surveyService.fetchSurveyResponses(testSurveyId);
      print('Found ${responses.length} responses');
      
      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        print('Response $i:');
        print('  ID: ${response.id}');
        print('  User: ${response.userId}');
        print('  Answers count: ${response.answers.length}');
        
        for (final answer in response.answers) {
          print('    Answer:');
          print('      Question ID: ${answer.surveyQuestionId}');
          print('      Value: ${answer.answerValue}');
          print('      Options: ${answer.selectedOptions}');
        }
      }
    } else {
      print('Failed to submit response');
    }
    
  } catch (e) {
    print('Error: $e');
  }
}
