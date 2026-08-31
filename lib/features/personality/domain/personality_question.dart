import 'personality_profile.dart';

class PersonalityQuestion {
  const PersonalityQuestion({required this.id, required this.trait, required this.text, this.reverse = false});
  final String id, text;
  final PersonalityTrait trait;
  final bool reverse;
}

const personalityQuestions = <PersonalityQuestion>[
  PersonalityQuestion(id: 'o1', trait: PersonalityTrait.openness, text: 'I enjoy trying new experiences.'),
  PersonalityQuestion(id: 'o2', trait: PersonalityTrait.openness, text: 'I like exploring different ideas.'),
  PersonalityQuestion(id: 'o3', trait: PersonalityTrait.openness, text: 'I prefer familiar routines.', reverse: true),
  PersonalityQuestion(id: 'c1', trait: PersonalityTrait.conscientiousness, text: 'I like having a plan.'),
  PersonalityQuestion(id: 'c2', trait: PersonalityTrait.conscientiousness, text: 'I keep track of things I need to do.'),
  PersonalityQuestion(id: 'c3', trait: PersonalityTrait.conscientiousness, text: 'I often leave tasks until the last minute.', reverse: true),
  PersonalityQuestion(id: 'e1', trait: PersonalityTrait.extraversion, text: 'Social interaction gives me energy.'),
  PersonalityQuestion(id: 'e2', trait: PersonalityTrait.extraversion, text: 'I am comfortable starting conversations.'),
  PersonalityQuestion(id: 'e3', trait: PersonalityTrait.extraversion, text: 'I prefer quiet time to social time.', reverse: true),
  PersonalityQuestion(id: 'a1', trait: PersonalityTrait.agreeableness, text: 'I try to consider other people’s feelings.'),
  PersonalityQuestion(id: 'a2', trait: PersonalityTrait.agreeableness, text: 'I enjoy helping people feel included.'),
  PersonalityQuestion(id: 'a3', trait: PersonalityTrait.agreeableness, text: 'I can be impatient with other people.', reverse: true),
  PersonalityQuestion(id: 's1', trait: PersonalityTrait.emotionalStability, text: 'I stay calm when plans change.'),
  PersonalityQuestion(id: 's2', trait: PersonalityTrait.emotionalStability, text: 'I recover fairly quickly from stressful moments.'),
  PersonalityQuestion(id: 's3', trait: PersonalityTrait.emotionalStability, text: 'Small problems easily overwhelm me.', reverse: true),
];
