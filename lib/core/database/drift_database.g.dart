// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $QuestionsTable extends Questions
    with TableInfo<$QuestionsTable, Question> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<String> chapter = GeneratedColumn<String>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _questionTextMeta = const VerificationMeta(
    'questionText',
  );
  @override
  late final GeneratedColumn<String> questionText = GeneratedColumn<String>(
    'question_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'options',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctAnswerMeta = const VerificationMeta(
    'correctAnswer',
  );
  @override
  late final GeneratedColumn<String> correctAnswer = GeneratedColumn<String>(
    'correct_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ncertReferenceMeta = const VerificationMeta(
    'ncertReference',
  );
  @override
  late final GeneratedColumn<String> ncertReference = GeneratedColumn<String>(
    'ncert_reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("Medium"),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("MCQ"),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('seeded'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subject,
    chapter,
    topic,
    topicId,
    questionText,
    options,
    correctAnswer,
    explanation,
    ncertReference,
    year,
    difficulty,
    tags,
    imageUrl,
    type,
    remoteId,
    updatedAt,
    isActive,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Question> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    }
    if (data.containsKey('question_text')) {
      context.handle(
        _questionTextMeta,
        questionText.isAcceptableOrUnknown(
          data['question_text']!,
          _questionTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionTextMeta);
    }
    if (data.containsKey('options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['options']!, _optionsMeta),
      );
    } else if (isInserting) {
      context.missing(_optionsMeta);
    }
    if (data.containsKey('correct_answer')) {
      context.handle(
        _correctAnswerMeta,
        correctAnswer.isAcceptableOrUnknown(
          data['correct_answer']!,
          _correctAnswerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctAnswerMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    }
    if (data.containsKey('ncert_reference')) {
      context.handle(
        _ncertReferenceMeta,
        ncertReference.isAcceptableOrUnknown(
          data['ncert_reference']!,
          _ncertReferenceMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Question map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Question(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      questionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_text'],
      )!,
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options'],
      )!,
      correctAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correct_answer'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      ),
      ncertReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ncert_reference'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $QuestionsTable createAlias(String alias) {
    return $QuestionsTable(attachedDatabase, alias);
  }
}

class Question extends DataClass implements Insertable<Question> {
  final String id;
  final String subject;
  final String chapter;
  final String topic;
  final String topicId;
  final String questionText;
  final String options;
  final String correctAnswer;
  final String? explanation;
  final String? ncertReference;
  final int? year;
  final String difficulty;
  final String? tags;
  final String? imageUrl;
  final String type;

  /// Supabase content-catalog UUID for remote-sourced questions.
  /// Null for the bundled sample bank.
  final String? remoteId;

  /// Last server-modified timestamp (delta sync watermark source).
  final DateTime? updatedAt;

  /// False once a catalog question is removed/deactivated on the server.
  final bool isActive;

  /// Origin of the question: 'seeded', 'pyq', 'dpp', 'imported'.
  final String source;
  const Question({
    required this.id,
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.topicId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.ncertReference,
    this.year,
    required this.difficulty,
    this.tags,
    this.imageUrl,
    required this.type,
    this.remoteId,
    this.updatedAt,
    required this.isActive,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject'] = Variable<String>(subject);
    map['chapter'] = Variable<String>(chapter);
    map['topic'] = Variable<String>(topic);
    map['topic_id'] = Variable<String>(topicId);
    map['question_text'] = Variable<String>(questionText);
    map['options'] = Variable<String>(options);
    map['correct_answer'] = Variable<String>(correctAnswer);
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    if (!nullToAbsent || ncertReference != null) {
      map['ncert_reference'] = Variable<String>(ncertReference);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['difficulty'] = Variable<String>(difficulty);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['source'] = Variable<String>(source);
    return map;
  }

  QuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuestionsCompanion(
      id: Value(id),
      subject: Value(subject),
      chapter: Value(chapter),
      topic: Value(topic),
      topicId: Value(topicId),
      questionText: Value(questionText),
      options: Value(options),
      correctAnswer: Value(correctAnswer),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      ncertReference: ncertReference == null && nullToAbsent
          ? const Value.absent()
          : Value(ncertReference),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      difficulty: Value(difficulty),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      type: Value(type),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isActive: Value(isActive),
      source: Value(source),
    );
  }

  factory Question.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Question(
      id: serializer.fromJson<String>(json['id']),
      subject: serializer.fromJson<String>(json['subject']),
      chapter: serializer.fromJson<String>(json['chapter']),
      topic: serializer.fromJson<String>(json['topic']),
      topicId: serializer.fromJson<String>(json['topicId']),
      questionText: serializer.fromJson<String>(json['questionText']),
      options: serializer.fromJson<String>(json['options']),
      correctAnswer: serializer.fromJson<String>(json['correctAnswer']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      ncertReference: serializer.fromJson<String?>(json['ncertReference']),
      year: serializer.fromJson<int?>(json['year']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      tags: serializer.fromJson<String?>(json['tags']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      type: serializer.fromJson<String>(json['type']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subject': serializer.toJson<String>(subject),
      'chapter': serializer.toJson<String>(chapter),
      'topic': serializer.toJson<String>(topic),
      'topicId': serializer.toJson<String>(topicId),
      'questionText': serializer.toJson<String>(questionText),
      'options': serializer.toJson<String>(options),
      'correctAnswer': serializer.toJson<String>(correctAnswer),
      'explanation': serializer.toJson<String?>(explanation),
      'ncertReference': serializer.toJson<String?>(ncertReference),
      'year': serializer.toJson<int?>(year),
      'difficulty': serializer.toJson<String>(difficulty),
      'tags': serializer.toJson<String?>(tags),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'type': serializer.toJson<String>(type),
      'remoteId': serializer.toJson<String?>(remoteId),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isActive': serializer.toJson<bool>(isActive),
      'source': serializer.toJson<String>(source),
    };
  }

  Question copyWith({
    String? id,
    String? subject,
    String? chapter,
    String? topic,
    String? topicId,
    String? questionText,
    String? options,
    String? correctAnswer,
    Value<String?> explanation = const Value.absent(),
    Value<String?> ncertReference = const Value.absent(),
    Value<int?> year = const Value.absent(),
    String? difficulty,
    Value<String?> tags = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    String? type,
    Value<String?> remoteId = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isActive,
    String? source,
  }) => Question(
    id: id ?? this.id,
    subject: subject ?? this.subject,
    chapter: chapter ?? this.chapter,
    topic: topic ?? this.topic,
    topicId: topicId ?? this.topicId,
    questionText: questionText ?? this.questionText,
    options: options ?? this.options,
    correctAnswer: correctAnswer ?? this.correctAnswer,
    explanation: explanation.present ? explanation.value : this.explanation,
    ncertReference: ncertReference.present
        ? ncertReference.value
        : this.ncertReference,
    year: year.present ? year.value : this.year,
    difficulty: difficulty ?? this.difficulty,
    tags: tags.present ? tags.value : this.tags,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    type: type ?? this.type,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isActive: isActive ?? this.isActive,
    source: source ?? this.source,
  );
  Question copyWithCompanion(QuestionsCompanion data) {
    return Question(
      id: data.id.present ? data.id.value : this.id,
      subject: data.subject.present ? data.subject.value : this.subject,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      topic: data.topic.present ? data.topic.value : this.topic,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      questionText: data.questionText.present
          ? data.questionText.value
          : this.questionText,
      options: data.options.present ? data.options.value : this.options,
      correctAnswer: data.correctAnswer.present
          ? data.correctAnswer.value
          : this.correctAnswer,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      ncertReference: data.ncertReference.present
          ? data.ncertReference.value
          : this.ncertReference,
      year: data.year.present ? data.year.value : this.year,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      tags: data.tags.present ? data.tags.value : this.tags,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      type: data.type.present ? data.type.value : this.type,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Question(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('chapter: $chapter, ')
          ..write('topic: $topic, ')
          ..write('topicId: $topicId, ')
          ..write('questionText: $questionText, ')
          ..write('options: $options, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('explanation: $explanation, ')
          ..write('ncertReference: $ncertReference, ')
          ..write('year: $year, ')
          ..write('difficulty: $difficulty, ')
          ..write('tags: $tags, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('type: $type, ')
          ..write('remoteId: $remoteId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subject,
    chapter,
    topic,
    topicId,
    questionText,
    options,
    correctAnswer,
    explanation,
    ncertReference,
    year,
    difficulty,
    tags,
    imageUrl,
    type,
    remoteId,
    updatedAt,
    isActive,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Question &&
          other.id == this.id &&
          other.subject == this.subject &&
          other.chapter == this.chapter &&
          other.topic == this.topic &&
          other.topicId == this.topicId &&
          other.questionText == this.questionText &&
          other.options == this.options &&
          other.correctAnswer == this.correctAnswer &&
          other.explanation == this.explanation &&
          other.ncertReference == this.ncertReference &&
          other.year == this.year &&
          other.difficulty == this.difficulty &&
          other.tags == this.tags &&
          other.imageUrl == this.imageUrl &&
          other.type == this.type &&
          other.remoteId == this.remoteId &&
          other.updatedAt == this.updatedAt &&
          other.isActive == this.isActive &&
          other.source == this.source);
}

class QuestionsCompanion extends UpdateCompanion<Question> {
  final Value<String> id;
  final Value<String> subject;
  final Value<String> chapter;
  final Value<String> topic;
  final Value<String> topicId;
  final Value<String> questionText;
  final Value<String> options;
  final Value<String> correctAnswer;
  final Value<String?> explanation;
  final Value<String?> ncertReference;
  final Value<int?> year;
  final Value<String> difficulty;
  final Value<String?> tags;
  final Value<String?> imageUrl;
  final Value<String> type;
  final Value<String?> remoteId;
  final Value<DateTime?> updatedAt;
  final Value<bool> isActive;
  final Value<String> source;
  final Value<int> rowid;
  const QuestionsCompanion({
    this.id = const Value.absent(),
    this.subject = const Value.absent(),
    this.chapter = const Value.absent(),
    this.topic = const Value.absent(),
    this.topicId = const Value.absent(),
    this.questionText = const Value.absent(),
    this.options = const Value.absent(),
    this.correctAnswer = const Value.absent(),
    this.explanation = const Value.absent(),
    this.ncertReference = const Value.absent(),
    this.year = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.tags = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.type = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionsCompanion.insert({
    required String id,
    required String subject,
    required String chapter,
    required String topic,
    this.topicId = const Value.absent(),
    required String questionText,
    required String options,
    required String correctAnswer,
    this.explanation = const Value.absent(),
    this.ncertReference = const Value.absent(),
    this.year = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.tags = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.type = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       subject = Value(subject),
       chapter = Value(chapter),
       topic = Value(topic),
       questionText = Value(questionText),
       options = Value(options),
       correctAnswer = Value(correctAnswer);
  static Insertable<Question> custom({
    Expression<String>? id,
    Expression<String>? subject,
    Expression<String>? chapter,
    Expression<String>? topic,
    Expression<String>? topicId,
    Expression<String>? questionText,
    Expression<String>? options,
    Expression<String>? correctAnswer,
    Expression<String>? explanation,
    Expression<String>? ncertReference,
    Expression<int>? year,
    Expression<String>? difficulty,
    Expression<String>? tags,
    Expression<String>? imageUrl,
    Expression<String>? type,
    Expression<String>? remoteId,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isActive,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subject != null) 'subject': subject,
      if (chapter != null) 'chapter': chapter,
      if (topic != null) 'topic': topic,
      if (topicId != null) 'topic_id': topicId,
      if (questionText != null) 'question_text': questionText,
      if (options != null) 'options': options,
      if (correctAnswer != null) 'correct_answer': correctAnswer,
      if (explanation != null) 'explanation': explanation,
      if (ncertReference != null) 'ncert_reference': ncertReference,
      if (year != null) 'year': year,
      if (difficulty != null) 'difficulty': difficulty,
      if (tags != null) 'tags': tags,
      if (imageUrl != null) 'image_url': imageUrl,
      if (type != null) 'type': type,
      if (remoteId != null) 'remote_id': remoteId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isActive != null) 'is_active': isActive,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? subject,
    Value<String>? chapter,
    Value<String>? topic,
    Value<String>? topicId,
    Value<String>? questionText,
    Value<String>? options,
    Value<String>? correctAnswer,
    Value<String?>? explanation,
    Value<String?>? ncertReference,
    Value<int?>? year,
    Value<String>? difficulty,
    Value<String?>? tags,
    Value<String?>? imageUrl,
    Value<String>? type,
    Value<String?>? remoteId,
    Value<DateTime?>? updatedAt,
    Value<bool>? isActive,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return QuestionsCompanion(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      topic: topic ?? this.topic,
      topicId: topicId ?? this.topicId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      ncertReference: ncertReference ?? this.ncertReference,
      year: year ?? this.year,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      remoteId: remoteId ?? this.remoteId,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<String>(chapter.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (questionText.present) {
      map['question_text'] = Variable<String>(questionText.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    if (correctAnswer.present) {
      map['correct_answer'] = Variable<String>(correctAnswer.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (ncertReference.present) {
      map['ncert_reference'] = Variable<String>(ncertReference.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionsCompanion(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('chapter: $chapter, ')
          ..write('topic: $topic, ')
          ..write('topicId: $topicId, ')
          ..write('questionText: $questionText, ')
          ..write('options: $options, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('explanation: $explanation, ')
          ..write('ncertReference: $ncertReference, ')
          ..write('year: $year, ')
          ..write('difficulty: $difficulty, ')
          ..write('tags: $tags, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('type: $type, ')
          ..write('remoteId: $remoteId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuizAttemptsTable extends QuizAttempts
    with TableInfo<$QuizAttemptsTable, QuizAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _incorrectCountMeta = const VerificationMeta(
    'incorrectCount',
  );
  @override
  late final GeneratedColumn<int> incorrectCount = GeneratedColumn<int>(
    'incorrect_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalQuestionsMeta = const VerificationMeta(
    'totalQuestions',
  );
  @override
  late final GeneratedColumn<int> totalQuestions = GeneratedColumn<int>(
    'total_questions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeSpentSecondsMeta = const VerificationMeta(
    'timeSpentSeconds',
  );
  @override
  late final GeneratedColumn<int> timeSpentSeconds = GeneratedColumn<int>(
    'time_spent_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptedAtMeta = const VerificationMeta(
    'attemptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> attemptedAt = GeneratedColumn<DateTime>(
    'attempted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedAnswersMeta = const VerificationMeta(
    'selectedAnswers',
  );
  @override
  late final GeneratedColumn<String> selectedAnswers = GeneratedColumn<String>(
    'selected_answers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _testTypeMeta = const VerificationMeta(
    'testType',
  );
  @override
  late final GeneratedColumn<String> testType = GeneratedColumn<String>(
    'test_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant("topic"),
  );
  static const VerificationMeta _subjectScoresMeta = const VerificationMeta(
    'subjectScores',
  );
  @override
  late final GeneratedColumn<String> subjectScores = GeneratedColumn<String>(
    'subject_scores',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawScoreMeta = const VerificationMeta(
    'rawScore',
  );
  @override
  late final GeneratedColumn<int> rawScore = GeneratedColumn<int>(
    'raw_score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxMarksMeta = const VerificationMeta(
    'maxMarks',
  );
  @override
  late final GeneratedColumn<int> maxMarks = GeneratedColumn<int>(
    'max_marks',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _questionIdsMeta = const VerificationMeta(
    'questionIds',
  );
  @override
  late final GeneratedColumn<String> questionIds = GeneratedColumn<String>(
    'question_ids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seedMeta = const VerificationMeta('seed');
  @override
  late final GeneratedColumn<int> seed = GeneratedColumn<int>(
    'seed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    topicId,
    subject,
    score,
    incorrectCount,
    totalQuestions,
    timeSpentSeconds,
    attemptedAt,
    selectedAnswers,
    testType,
    subjectScores,
    rawScore,
    maxMarks,
    questionIds,
    seed,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('incorrect_count')) {
      context.handle(
        _incorrectCountMeta,
        incorrectCount.isAcceptableOrUnknown(
          data['incorrect_count']!,
          _incorrectCountMeta,
        ),
      );
    }
    if (data.containsKey('total_questions')) {
      context.handle(
        _totalQuestionsMeta,
        totalQuestions.isAcceptableOrUnknown(
          data['total_questions']!,
          _totalQuestionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalQuestionsMeta);
    }
    if (data.containsKey('time_spent_seconds')) {
      context.handle(
        _timeSpentSecondsMeta,
        timeSpentSeconds.isAcceptableOrUnknown(
          data['time_spent_seconds']!,
          _timeSpentSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeSpentSecondsMeta);
    }
    if (data.containsKey('attempted_at')) {
      context.handle(
        _attemptedAtMeta,
        attemptedAt.isAcceptableOrUnknown(
          data['attempted_at']!,
          _attemptedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attemptedAtMeta);
    }
    if (data.containsKey('selected_answers')) {
      context.handle(
        _selectedAnswersMeta,
        selectedAnswers.isAcceptableOrUnknown(
          data['selected_answers']!,
          _selectedAnswersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_selectedAnswersMeta);
    }
    if (data.containsKey('test_type')) {
      context.handle(
        _testTypeMeta,
        testType.isAcceptableOrUnknown(data['test_type']!, _testTypeMeta),
      );
    }
    if (data.containsKey('subject_scores')) {
      context.handle(
        _subjectScoresMeta,
        subjectScores.isAcceptableOrUnknown(
          data['subject_scores']!,
          _subjectScoresMeta,
        ),
      );
    }
    if (data.containsKey('raw_score')) {
      context.handle(
        _rawScoreMeta,
        rawScore.isAcceptableOrUnknown(data['raw_score']!, _rawScoreMeta),
      );
    }
    if (data.containsKey('max_marks')) {
      context.handle(
        _maxMarksMeta,
        maxMarks.isAcceptableOrUnknown(data['max_marks']!, _maxMarksMeta),
      );
    }
    if (data.containsKey('question_ids')) {
      context.handle(
        _questionIdsMeta,
        questionIds.isAcceptableOrUnknown(
          data['question_ids']!,
          _questionIdsMeta,
        ),
      );
    }
    if (data.containsKey('seed')) {
      context.handle(
        _seedMeta,
        seed.isAcceptableOrUnknown(data['seed']!, _seedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuizAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      incorrectCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}incorrect_count'],
      )!,
      totalQuestions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_questions'],
      )!,
      timeSpentSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_spent_seconds'],
      )!,
      attemptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}attempted_at'],
      )!,
      selectedAnswers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_answers'],
      )!,
      testType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}test_type'],
      )!,
      subjectScores: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_scores'],
      ),
      rawScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}raw_score'],
      ),
      maxMarks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_marks'],
      ),
      questionIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_ids'],
      ),
      seed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $QuizAttemptsTable createAlias(String alias) {
    return $QuizAttemptsTable(attachedDatabase, alias);
  }
}

class QuizAttempt extends DataClass implements Insertable<QuizAttempt> {
  final int id;
  final String topicId;
  final String subject;
  final int score;
  final int incorrectCount;
  final int totalQuestions;
  final int timeSpentSeconds;
  final DateTime attemptedAt;
  final String selectedAnswers;
  final String testType;
  final String? subjectScores;
  final int? rawScore;
  final int? maxMarks;

  /// Ordered IDs of the questions presented in this attempt, JSON-encoded.
  /// Used to avoid repeating the same questions in later quizzes/mocks.
  final String? questionIds;

  /// Seed used to shuffle questions for this attempt so the order can be
  /// reproduced later for review or debugging.
  final int? seed;
  final DateTime? updatedAt;
  const QuizAttempt({
    required this.id,
    required this.topicId,
    required this.subject,
    required this.score,
    required this.incorrectCount,
    required this.totalQuestions,
    required this.timeSpentSeconds,
    required this.attemptedAt,
    required this.selectedAnswers,
    required this.testType,
    this.subjectScores,
    this.rawScore,
    this.maxMarks,
    this.questionIds,
    this.seed,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['topic_id'] = Variable<String>(topicId);
    map['subject'] = Variable<String>(subject);
    map['score'] = Variable<int>(score);
    map['incorrect_count'] = Variable<int>(incorrectCount);
    map['total_questions'] = Variable<int>(totalQuestions);
    map['time_spent_seconds'] = Variable<int>(timeSpentSeconds);
    map['attempted_at'] = Variable<DateTime>(attemptedAt);
    map['selected_answers'] = Variable<String>(selectedAnswers);
    map['test_type'] = Variable<String>(testType);
    if (!nullToAbsent || subjectScores != null) {
      map['subject_scores'] = Variable<String>(subjectScores);
    }
    if (!nullToAbsent || rawScore != null) {
      map['raw_score'] = Variable<int>(rawScore);
    }
    if (!nullToAbsent || maxMarks != null) {
      map['max_marks'] = Variable<int>(maxMarks);
    }
    if (!nullToAbsent || questionIds != null) {
      map['question_ids'] = Variable<String>(questionIds);
    }
    if (!nullToAbsent || seed != null) {
      map['seed'] = Variable<int>(seed);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  QuizAttemptsCompanion toCompanion(bool nullToAbsent) {
    return QuizAttemptsCompanion(
      id: Value(id),
      topicId: Value(topicId),
      subject: Value(subject),
      score: Value(score),
      incorrectCount: Value(incorrectCount),
      totalQuestions: Value(totalQuestions),
      timeSpentSeconds: Value(timeSpentSeconds),
      attemptedAt: Value(attemptedAt),
      selectedAnswers: Value(selectedAnswers),
      testType: Value(testType),
      subjectScores: subjectScores == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectScores),
      rawScore: rawScore == null && nullToAbsent
          ? const Value.absent()
          : Value(rawScore),
      maxMarks: maxMarks == null && nullToAbsent
          ? const Value.absent()
          : Value(maxMarks),
      questionIds: questionIds == null && nullToAbsent
          ? const Value.absent()
          : Value(questionIds),
      seed: seed == null && nullToAbsent ? const Value.absent() : Value(seed),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory QuizAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizAttempt(
      id: serializer.fromJson<int>(json['id']),
      topicId: serializer.fromJson<String>(json['topicId']),
      subject: serializer.fromJson<String>(json['subject']),
      score: serializer.fromJson<int>(json['score']),
      incorrectCount: serializer.fromJson<int>(json['incorrectCount']),
      totalQuestions: serializer.fromJson<int>(json['totalQuestions']),
      timeSpentSeconds: serializer.fromJson<int>(json['timeSpentSeconds']),
      attemptedAt: serializer.fromJson<DateTime>(json['attemptedAt']),
      selectedAnswers: serializer.fromJson<String>(json['selectedAnswers']),
      testType: serializer.fromJson<String>(json['testType']),
      subjectScores: serializer.fromJson<String?>(json['subjectScores']),
      rawScore: serializer.fromJson<int?>(json['rawScore']),
      maxMarks: serializer.fromJson<int?>(json['maxMarks']),
      questionIds: serializer.fromJson<String?>(json['questionIds']),
      seed: serializer.fromJson<int?>(json['seed']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'topicId': serializer.toJson<String>(topicId),
      'subject': serializer.toJson<String>(subject),
      'score': serializer.toJson<int>(score),
      'incorrectCount': serializer.toJson<int>(incorrectCount),
      'totalQuestions': serializer.toJson<int>(totalQuestions),
      'timeSpentSeconds': serializer.toJson<int>(timeSpentSeconds),
      'attemptedAt': serializer.toJson<DateTime>(attemptedAt),
      'selectedAnswers': serializer.toJson<String>(selectedAnswers),
      'testType': serializer.toJson<String>(testType),
      'subjectScores': serializer.toJson<String?>(subjectScores),
      'rawScore': serializer.toJson<int?>(rawScore),
      'maxMarks': serializer.toJson<int?>(maxMarks),
      'questionIds': serializer.toJson<String?>(questionIds),
      'seed': serializer.toJson<int?>(seed),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  QuizAttempt copyWith({
    int? id,
    String? topicId,
    String? subject,
    int? score,
    int? incorrectCount,
    int? totalQuestions,
    int? timeSpentSeconds,
    DateTime? attemptedAt,
    String? selectedAnswers,
    String? testType,
    Value<String?> subjectScores = const Value.absent(),
    Value<int?> rawScore = const Value.absent(),
    Value<int?> maxMarks = const Value.absent(),
    Value<String?> questionIds = const Value.absent(),
    Value<int?> seed = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => QuizAttempt(
    id: id ?? this.id,
    topicId: topicId ?? this.topicId,
    subject: subject ?? this.subject,
    score: score ?? this.score,
    incorrectCount: incorrectCount ?? this.incorrectCount,
    totalQuestions: totalQuestions ?? this.totalQuestions,
    timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    attemptedAt: attemptedAt ?? this.attemptedAt,
    selectedAnswers: selectedAnswers ?? this.selectedAnswers,
    testType: testType ?? this.testType,
    subjectScores: subjectScores.present
        ? subjectScores.value
        : this.subjectScores,
    rawScore: rawScore.present ? rawScore.value : this.rawScore,
    maxMarks: maxMarks.present ? maxMarks.value : this.maxMarks,
    questionIds: questionIds.present ? questionIds.value : this.questionIds,
    seed: seed.present ? seed.value : this.seed,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  QuizAttempt copyWithCompanion(QuizAttemptsCompanion data) {
    return QuizAttempt(
      id: data.id.present ? data.id.value : this.id,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      subject: data.subject.present ? data.subject.value : this.subject,
      score: data.score.present ? data.score.value : this.score,
      incorrectCount: data.incorrectCount.present
          ? data.incorrectCount.value
          : this.incorrectCount,
      totalQuestions: data.totalQuestions.present
          ? data.totalQuestions.value
          : this.totalQuestions,
      timeSpentSeconds: data.timeSpentSeconds.present
          ? data.timeSpentSeconds.value
          : this.timeSpentSeconds,
      attemptedAt: data.attemptedAt.present
          ? data.attemptedAt.value
          : this.attemptedAt,
      selectedAnswers: data.selectedAnswers.present
          ? data.selectedAnswers.value
          : this.selectedAnswers,
      testType: data.testType.present ? data.testType.value : this.testType,
      subjectScores: data.subjectScores.present
          ? data.subjectScores.value
          : this.subjectScores,
      rawScore: data.rawScore.present ? data.rawScore.value : this.rawScore,
      maxMarks: data.maxMarks.present ? data.maxMarks.value : this.maxMarks,
      questionIds: data.questionIds.present
          ? data.questionIds.value
          : this.questionIds,
      seed: data.seed.present ? data.seed.value : this.seed,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizAttempt(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('subject: $subject, ')
          ..write('score: $score, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('timeSpentSeconds: $timeSpentSeconds, ')
          ..write('attemptedAt: $attemptedAt, ')
          ..write('selectedAnswers: $selectedAnswers, ')
          ..write('testType: $testType, ')
          ..write('subjectScores: $subjectScores, ')
          ..write('rawScore: $rawScore, ')
          ..write('maxMarks: $maxMarks, ')
          ..write('questionIds: $questionIds, ')
          ..write('seed: $seed, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    topicId,
    subject,
    score,
    incorrectCount,
    totalQuestions,
    timeSpentSeconds,
    attemptedAt,
    selectedAnswers,
    testType,
    subjectScores,
    rawScore,
    maxMarks,
    questionIds,
    seed,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizAttempt &&
          other.id == this.id &&
          other.topicId == this.topicId &&
          other.subject == this.subject &&
          other.score == this.score &&
          other.incorrectCount == this.incorrectCount &&
          other.totalQuestions == this.totalQuestions &&
          other.timeSpentSeconds == this.timeSpentSeconds &&
          other.attemptedAt == this.attemptedAt &&
          other.selectedAnswers == this.selectedAnswers &&
          other.testType == this.testType &&
          other.subjectScores == this.subjectScores &&
          other.rawScore == this.rawScore &&
          other.maxMarks == this.maxMarks &&
          other.questionIds == this.questionIds &&
          other.seed == this.seed &&
          other.updatedAt == this.updatedAt);
}

class QuizAttemptsCompanion extends UpdateCompanion<QuizAttempt> {
  final Value<int> id;
  final Value<String> topicId;
  final Value<String> subject;
  final Value<int> score;
  final Value<int> incorrectCount;
  final Value<int> totalQuestions;
  final Value<int> timeSpentSeconds;
  final Value<DateTime> attemptedAt;
  final Value<String> selectedAnswers;
  final Value<String> testType;
  final Value<String?> subjectScores;
  final Value<int?> rawScore;
  final Value<int?> maxMarks;
  final Value<String?> questionIds;
  final Value<int?> seed;
  final Value<DateTime?> updatedAt;
  const QuizAttemptsCompanion({
    this.id = const Value.absent(),
    this.topicId = const Value.absent(),
    this.subject = const Value.absent(),
    this.score = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.timeSpentSeconds = const Value.absent(),
    this.attemptedAt = const Value.absent(),
    this.selectedAnswers = const Value.absent(),
    this.testType = const Value.absent(),
    this.subjectScores = const Value.absent(),
    this.rawScore = const Value.absent(),
    this.maxMarks = const Value.absent(),
    this.questionIds = const Value.absent(),
    this.seed = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  QuizAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String topicId,
    required String subject,
    required int score,
    this.incorrectCount = const Value.absent(),
    required int totalQuestions,
    required int timeSpentSeconds,
    required DateTime attemptedAt,
    required String selectedAnswers,
    this.testType = const Value.absent(),
    this.subjectScores = const Value.absent(),
    this.rawScore = const Value.absent(),
    this.maxMarks = const Value.absent(),
    this.questionIds = const Value.absent(),
    this.seed = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : topicId = Value(topicId),
       subject = Value(subject),
       score = Value(score),
       totalQuestions = Value(totalQuestions),
       timeSpentSeconds = Value(timeSpentSeconds),
       attemptedAt = Value(attemptedAt),
       selectedAnswers = Value(selectedAnswers);
  static Insertable<QuizAttempt> custom({
    Expression<int>? id,
    Expression<String>? topicId,
    Expression<String>? subject,
    Expression<int>? score,
    Expression<int>? incorrectCount,
    Expression<int>? totalQuestions,
    Expression<int>? timeSpentSeconds,
    Expression<DateTime>? attemptedAt,
    Expression<String>? selectedAnswers,
    Expression<String>? testType,
    Expression<String>? subjectScores,
    Expression<int>? rawScore,
    Expression<int>? maxMarks,
    Expression<String>? questionIds,
    Expression<int>? seed,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      if (subject != null) 'subject': subject,
      if (score != null) 'score': score,
      if (incorrectCount != null) 'incorrect_count': incorrectCount,
      if (totalQuestions != null) 'total_questions': totalQuestions,
      if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
      if (attemptedAt != null) 'attempted_at': attemptedAt,
      if (selectedAnswers != null) 'selected_answers': selectedAnswers,
      if (testType != null) 'test_type': testType,
      if (subjectScores != null) 'subject_scores': subjectScores,
      if (rawScore != null) 'raw_score': rawScore,
      if (maxMarks != null) 'max_marks': maxMarks,
      if (questionIds != null) 'question_ids': questionIds,
      if (seed != null) 'seed': seed,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  QuizAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? topicId,
    Value<String>? subject,
    Value<int>? score,
    Value<int>? incorrectCount,
    Value<int>? totalQuestions,
    Value<int>? timeSpentSeconds,
    Value<DateTime>? attemptedAt,
    Value<String>? selectedAnswers,
    Value<String>? testType,
    Value<String?>? subjectScores,
    Value<int?>? rawScore,
    Value<int?>? maxMarks,
    Value<String?>? questionIds,
    Value<int?>? seed,
    Value<DateTime?>? updatedAt,
  }) {
    return QuizAttemptsCompanion(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      subject: subject ?? this.subject,
      score: score ?? this.score,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      attemptedAt: attemptedAt ?? this.attemptedAt,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      testType: testType ?? this.testType,
      subjectScores: subjectScores ?? this.subjectScores,
      rawScore: rawScore ?? this.rawScore,
      maxMarks: maxMarks ?? this.maxMarks,
      questionIds: questionIds ?? this.questionIds,
      seed: seed ?? this.seed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (incorrectCount.present) {
      map['incorrect_count'] = Variable<int>(incorrectCount.value);
    }
    if (totalQuestions.present) {
      map['total_questions'] = Variable<int>(totalQuestions.value);
    }
    if (timeSpentSeconds.present) {
      map['time_spent_seconds'] = Variable<int>(timeSpentSeconds.value);
    }
    if (attemptedAt.present) {
      map['attempted_at'] = Variable<DateTime>(attemptedAt.value);
    }
    if (selectedAnswers.present) {
      map['selected_answers'] = Variable<String>(selectedAnswers.value);
    }
    if (testType.present) {
      map['test_type'] = Variable<String>(testType.value);
    }
    if (subjectScores.present) {
      map['subject_scores'] = Variable<String>(subjectScores.value);
    }
    if (rawScore.present) {
      map['raw_score'] = Variable<int>(rawScore.value);
    }
    if (maxMarks.present) {
      map['max_marks'] = Variable<int>(maxMarks.value);
    }
    if (questionIds.present) {
      map['question_ids'] = Variable<String>(questionIds.value);
    }
    if (seed.present) {
      map['seed'] = Variable<int>(seed.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('subject: $subject, ')
          ..write('score: $score, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('timeSpentSeconds: $timeSpentSeconds, ')
          ..write('attemptedAt: $attemptedAt, ')
          ..write('selectedAnswers: $selectedAnswers, ')
          ..write('testType: $testType, ')
          ..write('subjectScores: $subjectScores, ')
          ..write('rawScore: $rawScore, ')
          ..write('maxMarks: $maxMarks, ')
          ..write('questionIds: $questionIds, ')
          ..write('seed: $seed, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TopicProgressEntriesTable extends TopicProgressEntries
    with TableInfo<$TopicProgressEntriesTable, TopicProgressEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicProgressEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionsAttemptedMeta =
      const VerificationMeta('questionsAttempted');
  @override
  late final GeneratedColumn<int> questionsAttempted = GeneratedColumn<int>(
    'questions_attempted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _questionsCorrectMeta = const VerificationMeta(
    'questionsCorrect',
  );
  @override
  late final GeneratedColumn<int> questionsCorrect = GeneratedColumn<int>(
    'questions_correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timeSpentSecondsMeta = const VerificationMeta(
    'timeSpentSeconds',
  );
  @override
  late final GeneratedColumn<int> timeSpentSeconds = GeneratedColumn<int>(
    'time_spent_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _averageTimeSecondsMeta =
      const VerificationMeta('averageTimeSeconds');
  @override
  late final GeneratedColumn<double> averageTimeSeconds =
      GeneratedColumn<double>(
        'average_time_seconds',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _lastAttemptedMeta = const VerificationMeta(
    'lastAttempted',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttempted =
      GeneratedColumn<DateTime>(
        'last_attempted',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    topicId,
    questionsAttempted,
    questionsCorrect,
    timeSpentSeconds,
    averageTimeSeconds,
    lastAttempted,
    isCompleted,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topic_progress_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicProgressEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('questions_attempted')) {
      context.handle(
        _questionsAttemptedMeta,
        questionsAttempted.isAcceptableOrUnknown(
          data['questions_attempted']!,
          _questionsAttemptedMeta,
        ),
      );
    }
    if (data.containsKey('questions_correct')) {
      context.handle(
        _questionsCorrectMeta,
        questionsCorrect.isAcceptableOrUnknown(
          data['questions_correct']!,
          _questionsCorrectMeta,
        ),
      );
    }
    if (data.containsKey('time_spent_seconds')) {
      context.handle(
        _timeSpentSecondsMeta,
        timeSpentSeconds.isAcceptableOrUnknown(
          data['time_spent_seconds']!,
          _timeSpentSecondsMeta,
        ),
      );
    }
    if (data.containsKey('average_time_seconds')) {
      context.handle(
        _averageTimeSecondsMeta,
        averageTimeSeconds.isAcceptableOrUnknown(
          data['average_time_seconds']!,
          _averageTimeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('last_attempted')) {
      context.handle(
        _lastAttemptedMeta,
        lastAttempted.isAcceptableOrUnknown(
          data['last_attempted']!,
          _lastAttemptedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAttemptedMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {topicId};
  @override
  TopicProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicProgressEntry(
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      questionsAttempted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}questions_attempted'],
      )!,
      questionsCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}questions_correct'],
      )!,
      timeSpentSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_spent_seconds'],
      )!,
      averageTimeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_time_seconds'],
      )!,
      lastAttempted: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempted'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $TopicProgressEntriesTable createAlias(String alias) {
    return $TopicProgressEntriesTable(attachedDatabase, alias);
  }
}

class TopicProgressEntry extends DataClass
    implements Insertable<TopicProgressEntry> {
  final String topicId;
  final int questionsAttempted;
  final int questionsCorrect;
  final int timeSpentSeconds;
  final double averageTimeSeconds;
  final DateTime lastAttempted;
  final bool isCompleted;
  final DateTime? updatedAt;
  const TopicProgressEntry({
    required this.topicId,
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.timeSpentSeconds,
    required this.averageTimeSeconds,
    required this.lastAttempted,
    required this.isCompleted,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['topic_id'] = Variable<String>(topicId);
    map['questions_attempted'] = Variable<int>(questionsAttempted);
    map['questions_correct'] = Variable<int>(questionsCorrect);
    map['time_spent_seconds'] = Variable<int>(timeSpentSeconds);
    map['average_time_seconds'] = Variable<double>(averageTimeSeconds);
    map['last_attempted'] = Variable<DateTime>(lastAttempted);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  TopicProgressEntriesCompanion toCompanion(bool nullToAbsent) {
    return TopicProgressEntriesCompanion(
      topicId: Value(topicId),
      questionsAttempted: Value(questionsAttempted),
      questionsCorrect: Value(questionsCorrect),
      timeSpentSeconds: Value(timeSpentSeconds),
      averageTimeSeconds: Value(averageTimeSeconds),
      lastAttempted: Value(lastAttempted),
      isCompleted: Value(isCompleted),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory TopicProgressEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicProgressEntry(
      topicId: serializer.fromJson<String>(json['topicId']),
      questionsAttempted: serializer.fromJson<int>(json['questionsAttempted']),
      questionsCorrect: serializer.fromJson<int>(json['questionsCorrect']),
      timeSpentSeconds: serializer.fromJson<int>(json['timeSpentSeconds']),
      averageTimeSeconds: serializer.fromJson<double>(
        json['averageTimeSeconds'],
      ),
      lastAttempted: serializer.fromJson<DateTime>(json['lastAttempted']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'topicId': serializer.toJson<String>(topicId),
      'questionsAttempted': serializer.toJson<int>(questionsAttempted),
      'questionsCorrect': serializer.toJson<int>(questionsCorrect),
      'timeSpentSeconds': serializer.toJson<int>(timeSpentSeconds),
      'averageTimeSeconds': serializer.toJson<double>(averageTimeSeconds),
      'lastAttempted': serializer.toJson<DateTime>(lastAttempted),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  TopicProgressEntry copyWith({
    String? topicId,
    int? questionsAttempted,
    int? questionsCorrect,
    int? timeSpentSeconds,
    double? averageTimeSeconds,
    DateTime? lastAttempted,
    bool? isCompleted,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => TopicProgressEntry(
    topicId: topicId ?? this.topicId,
    questionsAttempted: questionsAttempted ?? this.questionsAttempted,
    questionsCorrect: questionsCorrect ?? this.questionsCorrect,
    timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    averageTimeSeconds: averageTimeSeconds ?? this.averageTimeSeconds,
    lastAttempted: lastAttempted ?? this.lastAttempted,
    isCompleted: isCompleted ?? this.isCompleted,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  TopicProgressEntry copyWithCompanion(TopicProgressEntriesCompanion data) {
    return TopicProgressEntry(
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      questionsAttempted: data.questionsAttempted.present
          ? data.questionsAttempted.value
          : this.questionsAttempted,
      questionsCorrect: data.questionsCorrect.present
          ? data.questionsCorrect.value
          : this.questionsCorrect,
      timeSpentSeconds: data.timeSpentSeconds.present
          ? data.timeSpentSeconds.value
          : this.timeSpentSeconds,
      averageTimeSeconds: data.averageTimeSeconds.present
          ? data.averageTimeSeconds.value
          : this.averageTimeSeconds,
      lastAttempted: data.lastAttempted.present
          ? data.lastAttempted.value
          : this.lastAttempted,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicProgressEntry(')
          ..write('topicId: $topicId, ')
          ..write('questionsAttempted: $questionsAttempted, ')
          ..write('questionsCorrect: $questionsCorrect, ')
          ..write('timeSpentSeconds: $timeSpentSeconds, ')
          ..write('averageTimeSeconds: $averageTimeSeconds, ')
          ..write('lastAttempted: $lastAttempted, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    topicId,
    questionsAttempted,
    questionsCorrect,
    timeSpentSeconds,
    averageTimeSeconds,
    lastAttempted,
    isCompleted,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicProgressEntry &&
          other.topicId == this.topicId &&
          other.questionsAttempted == this.questionsAttempted &&
          other.questionsCorrect == this.questionsCorrect &&
          other.timeSpentSeconds == this.timeSpentSeconds &&
          other.averageTimeSeconds == this.averageTimeSeconds &&
          other.lastAttempted == this.lastAttempted &&
          other.isCompleted == this.isCompleted &&
          other.updatedAt == this.updatedAt);
}

class TopicProgressEntriesCompanion
    extends UpdateCompanion<TopicProgressEntry> {
  final Value<String> topicId;
  final Value<int> questionsAttempted;
  final Value<int> questionsCorrect;
  final Value<int> timeSpentSeconds;
  final Value<double> averageTimeSeconds;
  final Value<DateTime> lastAttempted;
  final Value<bool> isCompleted;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const TopicProgressEntriesCompanion({
    this.topicId = const Value.absent(),
    this.questionsAttempted = const Value.absent(),
    this.questionsCorrect = const Value.absent(),
    this.timeSpentSeconds = const Value.absent(),
    this.averageTimeSeconds = const Value.absent(),
    this.lastAttempted = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TopicProgressEntriesCompanion.insert({
    required String topicId,
    this.questionsAttempted = const Value.absent(),
    this.questionsCorrect = const Value.absent(),
    this.timeSpentSeconds = const Value.absent(),
    this.averageTimeSeconds = const Value.absent(),
    required DateTime lastAttempted,
    this.isCompleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : topicId = Value(topicId),
       lastAttempted = Value(lastAttempted);
  static Insertable<TopicProgressEntry> custom({
    Expression<String>? topicId,
    Expression<int>? questionsAttempted,
    Expression<int>? questionsCorrect,
    Expression<int>? timeSpentSeconds,
    Expression<double>? averageTimeSeconds,
    Expression<DateTime>? lastAttempted,
    Expression<bool>? isCompleted,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (topicId != null) 'topic_id': topicId,
      if (questionsAttempted != null) 'questions_attempted': questionsAttempted,
      if (questionsCorrect != null) 'questions_correct': questionsCorrect,
      if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
      if (averageTimeSeconds != null)
        'average_time_seconds': averageTimeSeconds,
      if (lastAttempted != null) 'last_attempted': lastAttempted,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TopicProgressEntriesCompanion copyWith({
    Value<String>? topicId,
    Value<int>? questionsAttempted,
    Value<int>? questionsCorrect,
    Value<int>? timeSpentSeconds,
    Value<double>? averageTimeSeconds,
    Value<DateTime>? lastAttempted,
    Value<bool>? isCompleted,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return TopicProgressEntriesCompanion(
      topicId: topicId ?? this.topicId,
      questionsAttempted: questionsAttempted ?? this.questionsAttempted,
      questionsCorrect: questionsCorrect ?? this.questionsCorrect,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      averageTimeSeconds: averageTimeSeconds ?? this.averageTimeSeconds,
      lastAttempted: lastAttempted ?? this.lastAttempted,
      isCompleted: isCompleted ?? this.isCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (questionsAttempted.present) {
      map['questions_attempted'] = Variable<int>(questionsAttempted.value);
    }
    if (questionsCorrect.present) {
      map['questions_correct'] = Variable<int>(questionsCorrect.value);
    }
    if (timeSpentSeconds.present) {
      map['time_spent_seconds'] = Variable<int>(timeSpentSeconds.value);
    }
    if (averageTimeSeconds.present) {
      map['average_time_seconds'] = Variable<double>(averageTimeSeconds.value);
    }
    if (lastAttempted.present) {
      map['last_attempted'] = Variable<DateTime>(lastAttempted.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicProgressEntriesCompanion(')
          ..write('topicId: $topicId, ')
          ..write('questionsAttempted: $questionsAttempted, ')
          ..write('questionsCorrect: $questionsCorrect, ')
          ..write('timeSpentSeconds: $timeSpentSeconds, ')
          ..write('averageTimeSeconds: $averageTimeSeconds, ')
          ..write('lastAttempted: $lastAttempted, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookmarkedAtMeta = const VerificationMeta(
    'bookmarkedAt',
  );
  @override
  late final GeneratedColumn<DateTime> bookmarkedAt = GeneratedColumn<DateTime>(
    'bookmarked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questionId,
    subject,
    topicId,
    bookmarkedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('bookmarked_at')) {
      context.handle(
        _bookmarkedAtMeta,
        bookmarkedAt.isAcceptableOrUnknown(
          data['bookmarked_at']!,
          _bookmarkedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bookmarkedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      bookmarkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}bookmarked_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final int id;
  final String questionId;
  final String subject;
  final String topicId;
  final DateTime bookmarkedAt;
  final DateTime? updatedAt;
  const Bookmark({
    required this.id,
    required this.questionId,
    required this.subject,
    required this.topicId,
    required this.bookmarkedAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<String>(questionId);
    map['subject'] = Variable<String>(subject);
    map['topic_id'] = Variable<String>(topicId);
    map['bookmarked_at'] = Variable<DateTime>(bookmarkedAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      questionId: Value(questionId),
      subject: Value(subject),
      topicId: Value(topicId),
      bookmarkedAt: Value(bookmarkedAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      subject: serializer.fromJson<String>(json['subject']),
      topicId: serializer.fromJson<String>(json['topicId']),
      bookmarkedAt: serializer.fromJson<DateTime>(json['bookmarkedAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<String>(questionId),
      'subject': serializer.toJson<String>(subject),
      'topicId': serializer.toJson<String>(topicId),
      'bookmarkedAt': serializer.toJson<DateTime>(bookmarkedAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Bookmark copyWith({
    int? id,
    String? questionId,
    String? subject,
    String? topicId,
    DateTime? bookmarkedAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => Bookmark(
    id: id ?? this.id,
    questionId: questionId ?? this.questionId,
    subject: subject ?? this.subject,
    topicId: topicId ?? this.topicId,
    bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      subject: data.subject.present ? data.subject.value : this.subject,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      bookmarkedAt: data.bookmarkedAt.present
          ? data.bookmarkedAt.value
          : this.bookmarkedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('subject: $subject, ')
          ..write('topicId: $topicId, ')
          ..write('bookmarkedAt: $bookmarkedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, questionId, subject, topicId, bookmarkedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.subject == this.subject &&
          other.topicId == this.topicId &&
          other.bookmarkedAt == this.bookmarkedAt &&
          other.updatedAt == this.updatedAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<int> id;
  final Value<String> questionId;
  final Value<String> subject;
  final Value<String> topicId;
  final Value<DateTime> bookmarkedAt;
  final Value<DateTime?> updatedAt;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.subject = const Value.absent(),
    this.topicId = const Value.absent(),
    this.bookmarkedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    required String questionId,
    required String subject,
    required String topicId,
    required DateTime bookmarkedAt,
    this.updatedAt = const Value.absent(),
  }) : questionId = Value(questionId),
       subject = Value(subject),
       topicId = Value(topicId),
       bookmarkedAt = Value(bookmarkedAt);
  static Insertable<Bookmark> custom({
    Expression<int>? id,
    Expression<String>? questionId,
    Expression<String>? subject,
    Expression<String>? topicId,
    Expression<DateTime>? bookmarkedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (subject != null) 'subject': subject,
      if (topicId != null) 'topic_id': topicId,
      if (bookmarkedAt != null) 'bookmarked_at': bookmarkedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BookmarksCompanion copyWith({
    Value<int>? id,
    Value<String>? questionId,
    Value<String>? subject,
    Value<String>? topicId,
    Value<DateTime>? bookmarkedAt,
    Value<DateTime?>? updatedAt,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      subject: subject ?? this.subject,
      topicId: topicId ?? this.topicId,
      bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (bookmarkedAt.present) {
      map['bookmarked_at'] = Variable<DateTime>(bookmarkedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('subject: $subject, ')
          ..write('topicId: $topicId, ')
          ..write('bookmarkedAt: $bookmarkedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ChatsTable extends Chats with TableInfo<$ChatsTable, Chat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isUserMeta = const VerificationMeta('isUser');
  @override
  late final GeneratedColumn<bool> isUser = GeneratedColumn<bool>(
    'is_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_user" IN (0, 1))',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    message,
    isUser,
    timestamp,
    sessionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<Chat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('is_user')) {
      context.handle(
        _isUserMeta,
        isUser.isAcceptableOrUnknown(data['is_user']!, _isUserMeta),
      );
    } else if (isInserting) {
      context.missing(_isUserMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      isUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_user'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
    );
  }

  @override
  $ChatsTable createAlias(String alias) {
    return $ChatsTable(attachedDatabase, alias);
  }
}

class Chat extends DataClass implements Insertable<Chat> {
  final int id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? sessionId;
  const Chat({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.sessionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message'] = Variable<String>(message);
    map['is_user'] = Variable<bool>(isUser);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    return map;
  }

  ChatsCompanion toCompanion(bool nullToAbsent) {
    return ChatsCompanion(
      id: Value(id),
      message: Value(message),
      isUser: Value(isUser),
      timestamp: Value(timestamp),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
    );
  }

  factory Chat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chat(
      id: serializer.fromJson<int>(json['id']),
      message: serializer.fromJson<String>(json['message']),
      isUser: serializer.fromJson<bool>(json['isUser']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'message': serializer.toJson<String>(message),
      'isUser': serializer.toJson<bool>(isUser),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'sessionId': serializer.toJson<String?>(sessionId),
    };
  }

  Chat copyWith({
    int? id,
    String? message,
    bool? isUser,
    DateTime? timestamp,
    Value<String?> sessionId = const Value.absent(),
  }) => Chat(
    id: id ?? this.id,
    message: message ?? this.message,
    isUser: isUser ?? this.isUser,
    timestamp: timestamp ?? this.timestamp,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
  );
  Chat copyWithCompanion(ChatsCompanion data) {
    return Chat(
      id: data.id.present ? data.id.value : this.id,
      message: data.message.present ? data.message.value : this.message,
      isUser: data.isUser.present ? data.isUser.value : this.isUser,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chat(')
          ..write('id: $id, ')
          ..write('message: $message, ')
          ..write('isUser: $isUser, ')
          ..write('timestamp: $timestamp, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, message, isUser, timestamp, sessionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chat &&
          other.id == this.id &&
          other.message == this.message &&
          other.isUser == this.isUser &&
          other.timestamp == this.timestamp &&
          other.sessionId == this.sessionId);
}

class ChatsCompanion extends UpdateCompanion<Chat> {
  final Value<int> id;
  final Value<String> message;
  final Value<bool> isUser;
  final Value<DateTime> timestamp;
  final Value<String?> sessionId;
  const ChatsCompanion({
    this.id = const Value.absent(),
    this.message = const Value.absent(),
    this.isUser = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.sessionId = const Value.absent(),
  });
  ChatsCompanion.insert({
    this.id = const Value.absent(),
    required String message,
    required bool isUser,
    required DateTime timestamp,
    this.sessionId = const Value.absent(),
  }) : message = Value(message),
       isUser = Value(isUser),
       timestamp = Value(timestamp);
  static Insertable<Chat> custom({
    Expression<int>? id,
    Expression<String>? message,
    Expression<bool>? isUser,
    Expression<DateTime>? timestamp,
    Expression<String>? sessionId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (message != null) 'message': message,
      if (isUser != null) 'is_user': isUser,
      if (timestamp != null) 'timestamp': timestamp,
      if (sessionId != null) 'session_id': sessionId,
    });
  }

  ChatsCompanion copyWith({
    Value<int>? id,
    Value<String>? message,
    Value<bool>? isUser,
    Value<DateTime>? timestamp,
    Value<String?>? sessionId,
  }) {
    return ChatsCompanion(
      id: id ?? this.id,
      message: message ?? this.message,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (isUser.present) {
      map['is_user'] = Variable<bool>(isUser.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatsCompanion(')
          ..write('id: $id, ')
          ..write('message: $message, ')
          ..write('isUser: $isUser, ')
          ..write('timestamp: $timestamp, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }
}

class $DailyGoalsTable extends DailyGoals
    with TableInfo<$DailyGoalsTable, DailyGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<int> target = GeneratedColumn<int>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(50),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<int> completed = GeneratedColumn<int>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [date, target, completed, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyGoal(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $DailyGoalsTable createAlias(String alias) {
    return $DailyGoalsTable(attachedDatabase, alias);
  }
}

class DailyGoal extends DataClass implements Insertable<DailyGoal> {
  final DateTime date;
  final int target;
  final int completed;
  final String status;
  const DailyGoal({
    required this.date,
    required this.target,
    required this.completed,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<DateTime>(date);
    map['target'] = Variable<int>(target);
    map['completed'] = Variable<int>(completed);
    map['status'] = Variable<String>(status);
    return map;
  }

  DailyGoalsCompanion toCompanion(bool nullToAbsent) {
    return DailyGoalsCompanion(
      date: Value(date),
      target: Value(target),
      completed: Value(completed),
      status: Value(status),
    );
  }

  factory DailyGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyGoal(
      date: serializer.fromJson<DateTime>(json['date']),
      target: serializer.fromJson<int>(json['target']),
      completed: serializer.fromJson<int>(json['completed']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<DateTime>(date),
      'target': serializer.toJson<int>(target),
      'completed': serializer.toJson<int>(completed),
      'status': serializer.toJson<String>(status),
    };
  }

  DailyGoal copyWith({
    DateTime? date,
    int? target,
    int? completed,
    String? status,
  }) => DailyGoal(
    date: date ?? this.date,
    target: target ?? this.target,
    completed: completed ?? this.completed,
    status: status ?? this.status,
  );
  DailyGoal copyWithCompanion(DailyGoalsCompanion data) {
    return DailyGoal(
      date: data.date.present ? data.date.value : this.date,
      target: data.target.present ? data.target.value : this.target,
      completed: data.completed.present ? data.completed.value : this.completed,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyGoal(')
          ..write('date: $date, ')
          ..write('target: $target, ')
          ..write('completed: $completed, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, target, completed, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyGoal &&
          other.date == this.date &&
          other.target == this.target &&
          other.completed == this.completed &&
          other.status == this.status);
}

class DailyGoalsCompanion extends UpdateCompanion<DailyGoal> {
  final Value<DateTime> date;
  final Value<int> target;
  final Value<int> completed;
  final Value<String> status;
  final Value<int> rowid;
  const DailyGoalsCompanion({
    this.date = const Value.absent(),
    this.target = const Value.absent(),
    this.completed = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyGoalsCompanion.insert({
    required DateTime date,
    this.target = const Value.absent(),
    this.completed = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DailyGoal> custom({
    Expression<DateTime>? date,
    Expression<int>? target,
    Expression<int>? completed,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (target != null) 'target': target,
      if (completed != null) 'completed': completed,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyGoalsCompanion copyWith({
    Value<DateTime>? date,
    Value<int>? target,
    Value<int>? completed,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return DailyGoalsCompanion(
      date: date ?? this.date,
      target: target ?? this.target,
      completed: completed ?? this.completed,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (target.present) {
      map['target'] = Variable<int>(target.value);
    }
    if (completed.present) {
      map['completed'] = Variable<int>(completed.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyGoalsCompanion(')
          ..write('date: $date, ')
          ..write('target: $target, ')
          ..write('completed: $completed, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now()),
  );
  static const VerificationMeta _lastLoginMeta = const VerificationMeta(
    'lastLogin',
  );
  @override
  late final GeneratedColumn<DateTime> lastLogin = GeneratedColumn<DateTime>(
    'last_login',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isEmailVerifiedMeta = const VerificationMeta(
    'isEmailVerified',
  );
  @override
  late final GeneratedColumn<bool> isEmailVerified = GeneratedColumn<bool>(
    'is_email_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_email_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPhoneVerifiedMeta = const VerificationMeta(
    'isPhoneVerified',
  );
  @override
  late final GeneratedColumn<bool> isPhoneVerified = GeneratedColumn<bool>(
    'is_phone_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_phone_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isTwoFactorEnabledMeta =
      const VerificationMeta('isTwoFactorEnabled');
  @override
  late final GeneratedColumn<bool> isTwoFactorEnabled = GeneratedColumn<bool>(
    'is_two_factor_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_two_factor_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currentStreakMeta = const VerificationMeta(
    'currentStreak',
  );
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
    'current_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastActivityDateMeta = const VerificationMeta(
    'lastActivityDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastActivityDate =
      GeneratedColumn<DateTime>(
        'last_activity_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _batchMeta = const VerificationMeta('batch');
  @override
  late final GeneratedColumn<String> batch = GeneratedColumn<String>(
    'batch',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetYearMeta = const VerificationMeta(
    'targetYear',
  );
  @override
  late final GeneratedColumn<int> targetYear = GeneratedColumn<int>(
    'target_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dailyCommitmentMinutesMeta =
      const VerificationMeta('dailyCommitmentMinutes');
  @override
  late final GeneratedColumn<int> dailyCommitmentMinutes = GeneratedColumn<int>(
    'daily_commitment_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passwordResetCodeMeta = const VerificationMeta(
    'passwordResetCode',
  );
  @override
  late final GeneratedColumn<String> passwordResetCode =
      GeneratedColumn<String>(
        'password_reset_code',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _passwordResetExpiresAtMeta =
      const VerificationMeta('passwordResetExpiresAt');
  @override
  late final GeneratedColumn<DateTime> passwordResetExpiresAt =
      GeneratedColumn<DateTime>(
        'password_reset_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _twoFactorCodeMeta = const VerificationMeta(
    'twoFactorCode',
  );
  @override
  late final GeneratedColumn<String> twoFactorCode = GeneratedColumn<String>(
    'two_factor_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _twoFactorExpiresAtMeta =
      const VerificationMeta('twoFactorExpiresAt');
  @override
  late final GeneratedColumn<DateTime> twoFactorExpiresAt =
      GeneratedColumn<DateTime>(
        'two_factor_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
    'supabase_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    phone,
    username,
    passwordHash,
    fullName,
    createdAt,
    lastLogin,
    isActive,
    isEmailVerified,
    isPhoneVerified,
    isTwoFactorEnabled,
    currentStreak,
    lastActivityDate,
    batch,
    targetYear,
    dailyCommitmentMinutes,
    passwordResetCode,
    passwordResetExpiresAt,
    twoFactorCode,
    twoFactorExpiresAt,
    supabaseId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_login')) {
      context.handle(
        _lastLoginMeta,
        lastLogin.isAcceptableOrUnknown(data['last_login']!, _lastLoginMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('is_email_verified')) {
      context.handle(
        _isEmailVerifiedMeta,
        isEmailVerified.isAcceptableOrUnknown(
          data['is_email_verified']!,
          _isEmailVerifiedMeta,
        ),
      );
    }
    if (data.containsKey('is_phone_verified')) {
      context.handle(
        _isPhoneVerifiedMeta,
        isPhoneVerified.isAcceptableOrUnknown(
          data['is_phone_verified']!,
          _isPhoneVerifiedMeta,
        ),
      );
    }
    if (data.containsKey('is_two_factor_enabled')) {
      context.handle(
        _isTwoFactorEnabledMeta,
        isTwoFactorEnabled.isAcceptableOrUnknown(
          data['is_two_factor_enabled']!,
          _isTwoFactorEnabledMeta,
        ),
      );
    }
    if (data.containsKey('current_streak')) {
      context.handle(
        _currentStreakMeta,
        currentStreak.isAcceptableOrUnknown(
          data['current_streak']!,
          _currentStreakMeta,
        ),
      );
    }
    if (data.containsKey('last_activity_date')) {
      context.handle(
        _lastActivityDateMeta,
        lastActivityDate.isAcceptableOrUnknown(
          data['last_activity_date']!,
          _lastActivityDateMeta,
        ),
      );
    }
    if (data.containsKey('batch')) {
      context.handle(
        _batchMeta,
        batch.isAcceptableOrUnknown(data['batch']!, _batchMeta),
      );
    }
    if (data.containsKey('target_year')) {
      context.handle(
        _targetYearMeta,
        targetYear.isAcceptableOrUnknown(data['target_year']!, _targetYearMeta),
      );
    }
    if (data.containsKey('daily_commitment_minutes')) {
      context.handle(
        _dailyCommitmentMinutesMeta,
        dailyCommitmentMinutes.isAcceptableOrUnknown(
          data['daily_commitment_minutes']!,
          _dailyCommitmentMinutesMeta,
        ),
      );
    }
    if (data.containsKey('password_reset_code')) {
      context.handle(
        _passwordResetCodeMeta,
        passwordResetCode.isAcceptableOrUnknown(
          data['password_reset_code']!,
          _passwordResetCodeMeta,
        ),
      );
    }
    if (data.containsKey('password_reset_expires_at')) {
      context.handle(
        _passwordResetExpiresAtMeta,
        passwordResetExpiresAt.isAcceptableOrUnknown(
          data['password_reset_expires_at']!,
          _passwordResetExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('two_factor_code')) {
      context.handle(
        _twoFactorCodeMeta,
        twoFactorCode.isAcceptableOrUnknown(
          data['two_factor_code']!,
          _twoFactorCodeMeta,
        ),
      );
    }
    if (data.containsKey('two_factor_expires_at')) {
      context.handle(
        _twoFactorExpiresAtMeta,
        twoFactorExpiresAt.isAcceptableOrUnknown(
          data['two_factor_expires_at']!,
          _twoFactorExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      ),
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastLogin: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_login'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      isEmailVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_email_verified'],
      )!,
      isPhoneVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_phone_verified'],
      )!,
      isTwoFactorEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_two_factor_enabled'],
      )!,
      currentStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_streak'],
      )!,
      lastActivityDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_activity_date'],
      ),
      batch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch'],
      ),
      targetYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_year'],
      ),
      dailyCommitmentMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_commitment_minutes'],
      ),
      passwordResetCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_reset_code'],
      ),
      passwordResetExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}password_reset_expires_at'],
      ),
      twoFactorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}two_factor_code'],
      ),
      twoFactorExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}two_factor_expires_at'],
      ),
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supabase_id'],
      ),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String? email;
  final String? phone;
  final String username;
  final String? passwordHash;
  final String? fullName;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isTwoFactorEnabled;
  final int currentStreak;
  final DateTime? lastActivityDate;
  final String? batch;
  final int? targetYear;
  final int? dailyCommitmentMinutes;
  final String? passwordResetCode;
  final DateTime? passwordResetExpiresAt;
  final String? twoFactorCode;
  final DateTime? twoFactorExpiresAt;
  final String? supabaseId;
  const User({
    required this.id,
    this.email,
    this.phone,
    required this.username,
    this.passwordHash,
    this.fullName,
    required this.createdAt,
    this.lastLogin,
    required this.isActive,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isTwoFactorEnabled,
    required this.currentStreak,
    this.lastActivityDate,
    this.batch,
    this.targetYear,
    this.dailyCommitmentMinutes,
    this.passwordResetCode,
    this.passwordResetExpiresAt,
    this.twoFactorCode,
    this.twoFactorExpiresAt,
    this.supabaseId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || passwordHash != null) {
      map['password_hash'] = Variable<String>(passwordHash);
    }
    if (!nullToAbsent || fullName != null) {
      map['full_name'] = Variable<String>(fullName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastLogin != null) {
      map['last_login'] = Variable<DateTime>(lastLogin);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['is_email_verified'] = Variable<bool>(isEmailVerified);
    map['is_phone_verified'] = Variable<bool>(isPhoneVerified);
    map['is_two_factor_enabled'] = Variable<bool>(isTwoFactorEnabled);
    map['current_streak'] = Variable<int>(currentStreak);
    if (!nullToAbsent || lastActivityDate != null) {
      map['last_activity_date'] = Variable<DateTime>(lastActivityDate);
    }
    if (!nullToAbsent || batch != null) {
      map['batch'] = Variable<String>(batch);
    }
    if (!nullToAbsent || targetYear != null) {
      map['target_year'] = Variable<int>(targetYear);
    }
    if (!nullToAbsent || dailyCommitmentMinutes != null) {
      map['daily_commitment_minutes'] = Variable<int>(dailyCommitmentMinutes);
    }
    if (!nullToAbsent || passwordResetCode != null) {
      map['password_reset_code'] = Variable<String>(passwordResetCode);
    }
    if (!nullToAbsent || passwordResetExpiresAt != null) {
      map['password_reset_expires_at'] = Variable<DateTime>(
        passwordResetExpiresAt,
      );
    }
    if (!nullToAbsent || twoFactorCode != null) {
      map['two_factor_code'] = Variable<String>(twoFactorCode);
    }
    if (!nullToAbsent || twoFactorExpiresAt != null) {
      map['two_factor_expires_at'] = Variable<DateTime>(twoFactorExpiresAt);
    }
    if (!nullToAbsent || supabaseId != null) {
      map['supabase_id'] = Variable<String>(supabaseId);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      username: Value(username),
      passwordHash: passwordHash == null && nullToAbsent
          ? const Value.absent()
          : Value(passwordHash),
      fullName: fullName == null && nullToAbsent
          ? const Value.absent()
          : Value(fullName),
      createdAt: Value(createdAt),
      lastLogin: lastLogin == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLogin),
      isActive: Value(isActive),
      isEmailVerified: Value(isEmailVerified),
      isPhoneVerified: Value(isPhoneVerified),
      isTwoFactorEnabled: Value(isTwoFactorEnabled),
      currentStreak: Value(currentStreak),
      lastActivityDate: lastActivityDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActivityDate),
      batch: batch == null && nullToAbsent
          ? const Value.absent()
          : Value(batch),
      targetYear: targetYear == null && nullToAbsent
          ? const Value.absent()
          : Value(targetYear),
      dailyCommitmentMinutes: dailyCommitmentMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyCommitmentMinutes),
      passwordResetCode: passwordResetCode == null && nullToAbsent
          ? const Value.absent()
          : Value(passwordResetCode),
      passwordResetExpiresAt: passwordResetExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(passwordResetExpiresAt),
      twoFactorCode: twoFactorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(twoFactorCode),
      twoFactorExpiresAt: twoFactorExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(twoFactorExpiresAt),
      supabaseId: supabaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(supabaseId),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      email: serializer.fromJson<String?>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      username: serializer.fromJson<String>(json['username']),
      passwordHash: serializer.fromJson<String?>(json['passwordHash']),
      fullName: serializer.fromJson<String?>(json['fullName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastLogin: serializer.fromJson<DateTime?>(json['lastLogin']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isEmailVerified: serializer.fromJson<bool>(json['isEmailVerified']),
      isPhoneVerified: serializer.fromJson<bool>(json['isPhoneVerified']),
      isTwoFactorEnabled: serializer.fromJson<bool>(json['isTwoFactorEnabled']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      lastActivityDate: serializer.fromJson<DateTime?>(
        json['lastActivityDate'],
      ),
      batch: serializer.fromJson<String?>(json['batch']),
      targetYear: serializer.fromJson<int?>(json['targetYear']),
      dailyCommitmentMinutes: serializer.fromJson<int?>(
        json['dailyCommitmentMinutes'],
      ),
      passwordResetCode: serializer.fromJson<String?>(
        json['passwordResetCode'],
      ),
      passwordResetExpiresAt: serializer.fromJson<DateTime?>(
        json['passwordResetExpiresAt'],
      ),
      twoFactorCode: serializer.fromJson<String?>(json['twoFactorCode']),
      twoFactorExpiresAt: serializer.fromJson<DateTime?>(
        json['twoFactorExpiresAt'],
      ),
      supabaseId: serializer.fromJson<String?>(json['supabaseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'email': serializer.toJson<String?>(email),
      'phone': serializer.toJson<String?>(phone),
      'username': serializer.toJson<String>(username),
      'passwordHash': serializer.toJson<String?>(passwordHash),
      'fullName': serializer.toJson<String?>(fullName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastLogin': serializer.toJson<DateTime?>(lastLogin),
      'isActive': serializer.toJson<bool>(isActive),
      'isEmailVerified': serializer.toJson<bool>(isEmailVerified),
      'isPhoneVerified': serializer.toJson<bool>(isPhoneVerified),
      'isTwoFactorEnabled': serializer.toJson<bool>(isTwoFactorEnabled),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'lastActivityDate': serializer.toJson<DateTime?>(lastActivityDate),
      'batch': serializer.toJson<String?>(batch),
      'targetYear': serializer.toJson<int?>(targetYear),
      'dailyCommitmentMinutes': serializer.toJson<int?>(dailyCommitmentMinutes),
      'passwordResetCode': serializer.toJson<String?>(passwordResetCode),
      'passwordResetExpiresAt': serializer.toJson<DateTime?>(
        passwordResetExpiresAt,
      ),
      'twoFactorCode': serializer.toJson<String?>(twoFactorCode),
      'twoFactorExpiresAt': serializer.toJson<DateTime?>(twoFactorExpiresAt),
      'supabaseId': serializer.toJson<String?>(supabaseId),
    };
  }

  User copyWith({
    int? id,
    Value<String?> email = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    String? username,
    Value<String?> passwordHash = const Value.absent(),
    Value<String?> fullName = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> lastLogin = const Value.absent(),
    bool? isActive,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isTwoFactorEnabled,
    int? currentStreak,
    Value<DateTime?> lastActivityDate = const Value.absent(),
    Value<String?> batch = const Value.absent(),
    Value<int?> targetYear = const Value.absent(),
    Value<int?> dailyCommitmentMinutes = const Value.absent(),
    Value<String?> passwordResetCode = const Value.absent(),
    Value<DateTime?> passwordResetExpiresAt = const Value.absent(),
    Value<String?> twoFactorCode = const Value.absent(),
    Value<DateTime?> twoFactorExpiresAt = const Value.absent(),
    Value<String?> supabaseId = const Value.absent(),
  }) => User(
    id: id ?? this.id,
    email: email.present ? email.value : this.email,
    phone: phone.present ? phone.value : this.phone,
    username: username ?? this.username,
    passwordHash: passwordHash.present ? passwordHash.value : this.passwordHash,
    fullName: fullName.present ? fullName.value : this.fullName,
    createdAt: createdAt ?? this.createdAt,
    lastLogin: lastLogin.present ? lastLogin.value : this.lastLogin,
    isActive: isActive ?? this.isActive,
    isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
    currentStreak: currentStreak ?? this.currentStreak,
    lastActivityDate: lastActivityDate.present
        ? lastActivityDate.value
        : this.lastActivityDate,
    batch: batch.present ? batch.value : this.batch,
    targetYear: targetYear.present ? targetYear.value : this.targetYear,
    dailyCommitmentMinutes: dailyCommitmentMinutes.present
        ? dailyCommitmentMinutes.value
        : this.dailyCommitmentMinutes,
    passwordResetCode: passwordResetCode.present
        ? passwordResetCode.value
        : this.passwordResetCode,
    passwordResetExpiresAt: passwordResetExpiresAt.present
        ? passwordResetExpiresAt.value
        : this.passwordResetExpiresAt,
    twoFactorCode: twoFactorCode.present
        ? twoFactorCode.value
        : this.twoFactorCode,
    twoFactorExpiresAt: twoFactorExpiresAt.present
        ? twoFactorExpiresAt.value
        : this.twoFactorExpiresAt,
    supabaseId: supabaseId.present ? supabaseId.value : this.supabaseId,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      username: data.username.present ? data.username.value : this.username,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastLogin: data.lastLogin.present ? data.lastLogin.value : this.lastLogin,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isEmailVerified: data.isEmailVerified.present
          ? data.isEmailVerified.value
          : this.isEmailVerified,
      isPhoneVerified: data.isPhoneVerified.present
          ? data.isPhoneVerified.value
          : this.isPhoneVerified,
      isTwoFactorEnabled: data.isTwoFactorEnabled.present
          ? data.isTwoFactorEnabled.value
          : this.isTwoFactorEnabled,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      lastActivityDate: data.lastActivityDate.present
          ? data.lastActivityDate.value
          : this.lastActivityDate,
      batch: data.batch.present ? data.batch.value : this.batch,
      targetYear: data.targetYear.present
          ? data.targetYear.value
          : this.targetYear,
      dailyCommitmentMinutes: data.dailyCommitmentMinutes.present
          ? data.dailyCommitmentMinutes.value
          : this.dailyCommitmentMinutes,
      passwordResetCode: data.passwordResetCode.present
          ? data.passwordResetCode.value
          : this.passwordResetCode,
      passwordResetExpiresAt: data.passwordResetExpiresAt.present
          ? data.passwordResetExpiresAt.value
          : this.passwordResetExpiresAt,
      twoFactorCode: data.twoFactorCode.present
          ? data.twoFactorCode.value
          : this.twoFactorCode,
      twoFactorExpiresAt: data.twoFactorExpiresAt.present
          ? data.twoFactorExpiresAt.value
          : this.twoFactorExpiresAt,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('fullName: $fullName, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLogin: $lastLogin, ')
          ..write('isActive: $isActive, ')
          ..write('isEmailVerified: $isEmailVerified, ')
          ..write('isPhoneVerified: $isPhoneVerified, ')
          ..write('isTwoFactorEnabled: $isTwoFactorEnabled, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('lastActivityDate: $lastActivityDate, ')
          ..write('batch: $batch, ')
          ..write('targetYear: $targetYear, ')
          ..write('dailyCommitmentMinutes: $dailyCommitmentMinutes, ')
          ..write('passwordResetCode: $passwordResetCode, ')
          ..write('passwordResetExpiresAt: $passwordResetExpiresAt, ')
          ..write('twoFactorCode: $twoFactorCode, ')
          ..write('twoFactorExpiresAt: $twoFactorExpiresAt, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    email,
    phone,
    username,
    passwordHash,
    fullName,
    createdAt,
    lastLogin,
    isActive,
    isEmailVerified,
    isPhoneVerified,
    isTwoFactorEnabled,
    currentStreak,
    lastActivityDate,
    batch,
    targetYear,
    dailyCommitmentMinutes,
    passwordResetCode,
    passwordResetExpiresAt,
    twoFactorCode,
    twoFactorExpiresAt,
    supabaseId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.username == this.username &&
          other.passwordHash == this.passwordHash &&
          other.fullName == this.fullName &&
          other.createdAt == this.createdAt &&
          other.lastLogin == this.lastLogin &&
          other.isActive == this.isActive &&
          other.isEmailVerified == this.isEmailVerified &&
          other.isPhoneVerified == this.isPhoneVerified &&
          other.isTwoFactorEnabled == this.isTwoFactorEnabled &&
          other.currentStreak == this.currentStreak &&
          other.lastActivityDate == this.lastActivityDate &&
          other.batch == this.batch &&
          other.targetYear == this.targetYear &&
          other.dailyCommitmentMinutes == this.dailyCommitmentMinutes &&
          other.passwordResetCode == this.passwordResetCode &&
          other.passwordResetExpiresAt == this.passwordResetExpiresAt &&
          other.twoFactorCode == this.twoFactorCode &&
          other.twoFactorExpiresAt == this.twoFactorExpiresAt &&
          other.supabaseId == this.supabaseId);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String?> email;
  final Value<String?> phone;
  final Value<String> username;
  final Value<String?> passwordHash;
  final Value<String?> fullName;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastLogin;
  final Value<bool> isActive;
  final Value<bool> isEmailVerified;
  final Value<bool> isPhoneVerified;
  final Value<bool> isTwoFactorEnabled;
  final Value<int> currentStreak;
  final Value<DateTime?> lastActivityDate;
  final Value<String?> batch;
  final Value<int?> targetYear;
  final Value<int?> dailyCommitmentMinutes;
  final Value<String?> passwordResetCode;
  final Value<DateTime?> passwordResetExpiresAt;
  final Value<String?> twoFactorCode;
  final Value<DateTime?> twoFactorExpiresAt;
  final Value<String?> supabaseId;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.fullName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastLogin = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isEmailVerified = const Value.absent(),
    this.isPhoneVerified = const Value.absent(),
    this.isTwoFactorEnabled = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.lastActivityDate = const Value.absent(),
    this.batch = const Value.absent(),
    this.targetYear = const Value.absent(),
    this.dailyCommitmentMinutes = const Value.absent(),
    this.passwordResetCode = const Value.absent(),
    this.passwordResetExpiresAt = const Value.absent(),
    this.twoFactorCode = const Value.absent(),
    this.twoFactorExpiresAt = const Value.absent(),
    this.supabaseId = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    required String username,
    this.passwordHash = const Value.absent(),
    this.fullName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastLogin = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isEmailVerified = const Value.absent(),
    this.isPhoneVerified = const Value.absent(),
    this.isTwoFactorEnabled = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.lastActivityDate = const Value.absent(),
    this.batch = const Value.absent(),
    this.targetYear = const Value.absent(),
    this.dailyCommitmentMinutes = const Value.absent(),
    this.passwordResetCode = const Value.absent(),
    this.passwordResetExpiresAt = const Value.absent(),
    this.twoFactorCode = const Value.absent(),
    this.twoFactorExpiresAt = const Value.absent(),
    this.supabaseId = const Value.absent(),
  }) : username = Value(username);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? username,
    Expression<String>? passwordHash,
    Expression<String>? fullName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastLogin,
    Expression<bool>? isActive,
    Expression<bool>? isEmailVerified,
    Expression<bool>? isPhoneVerified,
    Expression<bool>? isTwoFactorEnabled,
    Expression<int>? currentStreak,
    Expression<DateTime>? lastActivityDate,
    Expression<String>? batch,
    Expression<int>? targetYear,
    Expression<int>? dailyCommitmentMinutes,
    Expression<String>? passwordResetCode,
    Expression<DateTime>? passwordResetExpiresAt,
    Expression<String>? twoFactorCode,
    Expression<DateTime>? twoFactorExpiresAt,
    Expression<String>? supabaseId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (username != null) 'username': username,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (fullName != null) 'full_name': fullName,
      if (createdAt != null) 'created_at': createdAt,
      if (lastLogin != null) 'last_login': lastLogin,
      if (isActive != null) 'is_active': isActive,
      if (isEmailVerified != null) 'is_email_verified': isEmailVerified,
      if (isPhoneVerified != null) 'is_phone_verified': isPhoneVerified,
      if (isTwoFactorEnabled != null)
        'is_two_factor_enabled': isTwoFactorEnabled,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (lastActivityDate != null) 'last_activity_date': lastActivityDate,
      if (batch != null) 'batch': batch,
      if (targetYear != null) 'target_year': targetYear,
      if (dailyCommitmentMinutes != null)
        'daily_commitment_minutes': dailyCommitmentMinutes,
      if (passwordResetCode != null) 'password_reset_code': passwordResetCode,
      if (passwordResetExpiresAt != null)
        'password_reset_expires_at': passwordResetExpiresAt,
      if (twoFactorCode != null) 'two_factor_code': twoFactorCode,
      if (twoFactorExpiresAt != null)
        'two_factor_expires_at': twoFactorExpiresAt,
      if (supabaseId != null) 'supabase_id': supabaseId,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String?>? email,
    Value<String?>? phone,
    Value<String>? username,
    Value<String?>? passwordHash,
    Value<String?>? fullName,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastLogin,
    Value<bool>? isActive,
    Value<bool>? isEmailVerified,
    Value<bool>? isPhoneVerified,
    Value<bool>? isTwoFactorEnabled,
    Value<int>? currentStreak,
    Value<DateTime?>? lastActivityDate,
    Value<String?>? batch,
    Value<int?>? targetYear,
    Value<int?>? dailyCommitmentMinutes,
    Value<String?>? passwordResetCode,
    Value<DateTime?>? passwordResetExpiresAt,
    Value<String?>? twoFactorCode,
    Value<DateTime?>? twoFactorExpiresAt,
    Value<String?>? supabaseId,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      currentStreak: currentStreak ?? this.currentStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      batch: batch ?? this.batch,
      targetYear: targetYear ?? this.targetYear,
      dailyCommitmentMinutes:
          dailyCommitmentMinutes ?? this.dailyCommitmentMinutes,
      passwordResetCode: passwordResetCode ?? this.passwordResetCode,
      passwordResetExpiresAt:
          passwordResetExpiresAt ?? this.passwordResetExpiresAt,
      twoFactorCode: twoFactorCode ?? this.twoFactorCode,
      twoFactorExpiresAt: twoFactorExpiresAt ?? this.twoFactorExpiresAt,
      supabaseId: supabaseId ?? this.supabaseId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastLogin.present) {
      map['last_login'] = Variable<DateTime>(lastLogin.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isEmailVerified.present) {
      map['is_email_verified'] = Variable<bool>(isEmailVerified.value);
    }
    if (isPhoneVerified.present) {
      map['is_phone_verified'] = Variable<bool>(isPhoneVerified.value);
    }
    if (isTwoFactorEnabled.present) {
      map['is_two_factor_enabled'] = Variable<bool>(isTwoFactorEnabled.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (lastActivityDate.present) {
      map['last_activity_date'] = Variable<DateTime>(lastActivityDate.value);
    }
    if (batch.present) {
      map['batch'] = Variable<String>(batch.value);
    }
    if (targetYear.present) {
      map['target_year'] = Variable<int>(targetYear.value);
    }
    if (dailyCommitmentMinutes.present) {
      map['daily_commitment_minutes'] = Variable<int>(
        dailyCommitmentMinutes.value,
      );
    }
    if (passwordResetCode.present) {
      map['password_reset_code'] = Variable<String>(passwordResetCode.value);
    }
    if (passwordResetExpiresAt.present) {
      map['password_reset_expires_at'] = Variable<DateTime>(
        passwordResetExpiresAt.value,
      );
    }
    if (twoFactorCode.present) {
      map['two_factor_code'] = Variable<String>(twoFactorCode.value);
    }
    if (twoFactorExpiresAt.present) {
      map['two_factor_expires_at'] = Variable<DateTime>(
        twoFactorExpiresAt.value,
      );
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('fullName: $fullName, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLogin: $lastLogin, ')
          ..write('isActive: $isActive, ')
          ..write('isEmailVerified: $isEmailVerified, ')
          ..write('isPhoneVerified: $isPhoneVerified, ')
          ..write('isTwoFactorEnabled: $isTwoFactorEnabled, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('lastActivityDate: $lastActivityDate, ')
          ..write('batch: $batch, ')
          ..write('targetYear: $targetYear, ')
          ..write('dailyCommitmentMinutes: $dailyCommitmentMinutes, ')
          ..write('passwordResetCode: $passwordResetCode, ')
          ..write('passwordResetExpiresAt: $passwordResetExpiresAt, ')
          ..write('twoFactorCode: $twoFactorCode, ')
          ..write('twoFactorExpiresAt: $twoFactorExpiresAt, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }
}

class $ErrorBookTable extends ErrorBook
    with TableInfo<$ErrorBookTable, ErrorBookData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ErrorBookTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isResolvedMeta = const VerificationMeta(
    'isResolved',
  );
  @override
  late final GeneratedColumn<bool> isResolved = GeneratedColumn<bool>(
    'is_resolved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_resolved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    questionId,
    addedAt,
    retryCount,
    isResolved,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'error_book';
  @override
  VerificationContext validateIntegrity(
    Insertable<ErrorBookData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('is_resolved')) {
      context.handle(
        _isResolvedMeta,
        isResolved.isAcceptableOrUnknown(data['is_resolved']!, _isResolvedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionId};
  @override
  ErrorBookData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ErrorBookData(
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      isResolved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_resolved'],
      )!,
    );
  }

  @override
  $ErrorBookTable createAlias(String alias) {
    return $ErrorBookTable(attachedDatabase, alias);
  }
}

class ErrorBookData extends DataClass implements Insertable<ErrorBookData> {
  final String questionId;
  final DateTime addedAt;
  final int retryCount;
  final bool isResolved;
  const ErrorBookData({
    required this.questionId,
    required this.addedAt,
    required this.retryCount,
    required this.isResolved,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_id'] = Variable<String>(questionId);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['retry_count'] = Variable<int>(retryCount);
    map['is_resolved'] = Variable<bool>(isResolved);
    return map;
  }

  ErrorBookCompanion toCompanion(bool nullToAbsent) {
    return ErrorBookCompanion(
      questionId: Value(questionId),
      addedAt: Value(addedAt),
      retryCount: Value(retryCount),
      isResolved: Value(isResolved),
    );
  }

  factory ErrorBookData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ErrorBookData(
      questionId: serializer.fromJson<String>(json['questionId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      isResolved: serializer.fromJson<bool>(json['isResolved']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionId': serializer.toJson<String>(questionId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'isResolved': serializer.toJson<bool>(isResolved),
    };
  }

  ErrorBookData copyWith({
    String? questionId,
    DateTime? addedAt,
    int? retryCount,
    bool? isResolved,
  }) => ErrorBookData(
    questionId: questionId ?? this.questionId,
    addedAt: addedAt ?? this.addedAt,
    retryCount: retryCount ?? this.retryCount,
    isResolved: isResolved ?? this.isResolved,
  );
  ErrorBookData copyWithCompanion(ErrorBookCompanion data) {
    return ErrorBookData(
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      isResolved: data.isResolved.present
          ? data.isResolved.value
          : this.isResolved,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ErrorBookData(')
          ..write('questionId: $questionId, ')
          ..write('addedAt: $addedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('isResolved: $isResolved')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(questionId, addedAt, retryCount, isResolved);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ErrorBookData &&
          other.questionId == this.questionId &&
          other.addedAt == this.addedAt &&
          other.retryCount == this.retryCount &&
          other.isResolved == this.isResolved);
}

class ErrorBookCompanion extends UpdateCompanion<ErrorBookData> {
  final Value<String> questionId;
  final Value<DateTime> addedAt;
  final Value<int> retryCount;
  final Value<bool> isResolved;
  final Value<int> rowid;
  const ErrorBookCompanion({
    this.questionId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.isResolved = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ErrorBookCompanion.insert({
    required String questionId,
    required DateTime addedAt,
    this.retryCount = const Value.absent(),
    this.isResolved = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : questionId = Value(questionId),
       addedAt = Value(addedAt);
  static Insertable<ErrorBookData> custom({
    Expression<String>? questionId,
    Expression<DateTime>? addedAt,
    Expression<int>? retryCount,
    Expression<bool>? isResolved,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionId != null) 'question_id': questionId,
      if (addedAt != null) 'added_at': addedAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (isResolved != null) 'is_resolved': isResolved,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ErrorBookCompanion copyWith({
    Value<String>? questionId,
    Value<DateTime>? addedAt,
    Value<int>? retryCount,
    Value<bool>? isResolved,
    Value<int>? rowid,
  }) {
    return ErrorBookCompanion(
      questionId: questionId ?? this.questionId,
      addedAt: addedAt ?? this.addedAt,
      retryCount: retryCount ?? this.retryCount,
      isResolved: isResolved ?? this.isResolved,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (isResolved.present) {
      map['is_resolved'] = Variable<bool>(isResolved.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ErrorBookCompanion(')
          ..write('questionId: $questionId, ')
          ..write('addedAt: $addedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('isResolved: $isResolved, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvaluationsTable extends Evaluations
    with TableInfo<$EvaluationsTable, Evaluation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvaluationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentAnswerMeta = const VerificationMeta(
    'studentAnswer',
  );
  @override
  late final GeneratedColumn<String> studentAnswer = GeneratedColumn<String>(
    'student_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semanticSimilarityMeta =
      const VerificationMeta('semanticSimilarity');
  @override
  late final GeneratedColumn<double> semanticSimilarity =
      GeneratedColumn<double>(
        'semantic_similarity',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _keywordMatchMeta = const VerificationMeta(
    'keywordMatch',
  );
  @override
  late final GeneratedColumn<double> keywordMatch = GeneratedColumn<double>(
    'keyword_match',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCorrectMeta = const VerificationMeta(
    'isCorrect',
  );
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
    'is_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _feedbackMeta = const VerificationMeta(
    'feedback',
  );
  @override
  late final GeneratedColumn<String> feedback = GeneratedColumn<String>(
    'feedback',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _missingKeywordsMeta = const VerificationMeta(
    'missingKeywords',
  );
  @override
  late final GeneratedColumn<String> missingKeywords = GeneratedColumn<String>(
    'missing_keywords',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _evaluatedAtMeta = const VerificationMeta(
    'evaluatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> evaluatedAt = GeneratedColumn<DateTime>(
    'evaluated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questionId,
    studentAnswer,
    score,
    semanticSimilarity,
    keywordMatch,
    isCorrect,
    feedback,
    missingKeywords,
    evaluatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evaluations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Evaluation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('student_answer')) {
      context.handle(
        _studentAnswerMeta,
        studentAnswer.isAcceptableOrUnknown(
          data['student_answer']!,
          _studentAnswerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studentAnswerMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('semantic_similarity')) {
      context.handle(
        _semanticSimilarityMeta,
        semanticSimilarity.isAcceptableOrUnknown(
          data['semantic_similarity']!,
          _semanticSimilarityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_semanticSimilarityMeta);
    }
    if (data.containsKey('keyword_match')) {
      context.handle(
        _keywordMatchMeta,
        keywordMatch.isAcceptableOrUnknown(
          data['keyword_match']!,
          _keywordMatchMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keywordMatchMeta);
    }
    if (data.containsKey('is_correct')) {
      context.handle(
        _isCorrectMeta,
        isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta),
      );
    } else if (isInserting) {
      context.missing(_isCorrectMeta);
    }
    if (data.containsKey('feedback')) {
      context.handle(
        _feedbackMeta,
        feedback.isAcceptableOrUnknown(data['feedback']!, _feedbackMeta),
      );
    }
    if (data.containsKey('missing_keywords')) {
      context.handle(
        _missingKeywordsMeta,
        missingKeywords.isAcceptableOrUnknown(
          data['missing_keywords']!,
          _missingKeywordsMeta,
        ),
      );
    }
    if (data.containsKey('evaluated_at')) {
      context.handle(
        _evaluatedAtMeta,
        evaluatedAt.isAcceptableOrUnknown(
          data['evaluated_at']!,
          _evaluatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evaluatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Evaluation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Evaluation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      studentAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_answer'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      semanticSimilarity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}semantic_similarity'],
      )!,
      keywordMatch: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}keyword_match'],
      )!,
      isCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct'],
      )!,
      feedback: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feedback'],
      ),
      missingKeywords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}missing_keywords'],
      ),
      evaluatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}evaluated_at'],
      )!,
    );
  }

  @override
  $EvaluationsTable createAlias(String alias) {
    return $EvaluationsTable(attachedDatabase, alias);
  }
}

class Evaluation extends DataClass implements Insertable<Evaluation> {
  final int id;
  final String questionId;
  final String studentAnswer;
  final double score;
  final double semanticSimilarity;
  final double keywordMatch;
  final bool isCorrect;
  final String? feedback;
  final String? missingKeywords;
  final DateTime evaluatedAt;
  const Evaluation({
    required this.id,
    required this.questionId,
    required this.studentAnswer,
    required this.score,
    required this.semanticSimilarity,
    required this.keywordMatch,
    required this.isCorrect,
    this.feedback,
    this.missingKeywords,
    required this.evaluatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<String>(questionId);
    map['student_answer'] = Variable<String>(studentAnswer);
    map['score'] = Variable<double>(score);
    map['semantic_similarity'] = Variable<double>(semanticSimilarity);
    map['keyword_match'] = Variable<double>(keywordMatch);
    map['is_correct'] = Variable<bool>(isCorrect);
    if (!nullToAbsent || feedback != null) {
      map['feedback'] = Variable<String>(feedback);
    }
    if (!nullToAbsent || missingKeywords != null) {
      map['missing_keywords'] = Variable<String>(missingKeywords);
    }
    map['evaluated_at'] = Variable<DateTime>(evaluatedAt);
    return map;
  }

  EvaluationsCompanion toCompanion(bool nullToAbsent) {
    return EvaluationsCompanion(
      id: Value(id),
      questionId: Value(questionId),
      studentAnswer: Value(studentAnswer),
      score: Value(score),
      semanticSimilarity: Value(semanticSimilarity),
      keywordMatch: Value(keywordMatch),
      isCorrect: Value(isCorrect),
      feedback: feedback == null && nullToAbsent
          ? const Value.absent()
          : Value(feedback),
      missingKeywords: missingKeywords == null && nullToAbsent
          ? const Value.absent()
          : Value(missingKeywords),
      evaluatedAt: Value(evaluatedAt),
    );
  }

  factory Evaluation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Evaluation(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      studentAnswer: serializer.fromJson<String>(json['studentAnswer']),
      score: serializer.fromJson<double>(json['score']),
      semanticSimilarity: serializer.fromJson<double>(
        json['semanticSimilarity'],
      ),
      keywordMatch: serializer.fromJson<double>(json['keywordMatch']),
      isCorrect: serializer.fromJson<bool>(json['isCorrect']),
      feedback: serializer.fromJson<String?>(json['feedback']),
      missingKeywords: serializer.fromJson<String?>(json['missingKeywords']),
      evaluatedAt: serializer.fromJson<DateTime>(json['evaluatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<String>(questionId),
      'studentAnswer': serializer.toJson<String>(studentAnswer),
      'score': serializer.toJson<double>(score),
      'semanticSimilarity': serializer.toJson<double>(semanticSimilarity),
      'keywordMatch': serializer.toJson<double>(keywordMatch),
      'isCorrect': serializer.toJson<bool>(isCorrect),
      'feedback': serializer.toJson<String?>(feedback),
      'missingKeywords': serializer.toJson<String?>(missingKeywords),
      'evaluatedAt': serializer.toJson<DateTime>(evaluatedAt),
    };
  }

  Evaluation copyWith({
    int? id,
    String? questionId,
    String? studentAnswer,
    double? score,
    double? semanticSimilarity,
    double? keywordMatch,
    bool? isCorrect,
    Value<String?> feedback = const Value.absent(),
    Value<String?> missingKeywords = const Value.absent(),
    DateTime? evaluatedAt,
  }) => Evaluation(
    id: id ?? this.id,
    questionId: questionId ?? this.questionId,
    studentAnswer: studentAnswer ?? this.studentAnswer,
    score: score ?? this.score,
    semanticSimilarity: semanticSimilarity ?? this.semanticSimilarity,
    keywordMatch: keywordMatch ?? this.keywordMatch,
    isCorrect: isCorrect ?? this.isCorrect,
    feedback: feedback.present ? feedback.value : this.feedback,
    missingKeywords: missingKeywords.present
        ? missingKeywords.value
        : this.missingKeywords,
    evaluatedAt: evaluatedAt ?? this.evaluatedAt,
  );
  Evaluation copyWithCompanion(EvaluationsCompanion data) {
    return Evaluation(
      id: data.id.present ? data.id.value : this.id,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      studentAnswer: data.studentAnswer.present
          ? data.studentAnswer.value
          : this.studentAnswer,
      score: data.score.present ? data.score.value : this.score,
      semanticSimilarity: data.semanticSimilarity.present
          ? data.semanticSimilarity.value
          : this.semanticSimilarity,
      keywordMatch: data.keywordMatch.present
          ? data.keywordMatch.value
          : this.keywordMatch,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      feedback: data.feedback.present ? data.feedback.value : this.feedback,
      missingKeywords: data.missingKeywords.present
          ? data.missingKeywords.value
          : this.missingKeywords,
      evaluatedAt: data.evaluatedAt.present
          ? data.evaluatedAt.value
          : this.evaluatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Evaluation(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('studentAnswer: $studentAnswer, ')
          ..write('score: $score, ')
          ..write('semanticSimilarity: $semanticSimilarity, ')
          ..write('keywordMatch: $keywordMatch, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('feedback: $feedback, ')
          ..write('missingKeywords: $missingKeywords, ')
          ..write('evaluatedAt: $evaluatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    questionId,
    studentAnswer,
    score,
    semanticSimilarity,
    keywordMatch,
    isCorrect,
    feedback,
    missingKeywords,
    evaluatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Evaluation &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.studentAnswer == this.studentAnswer &&
          other.score == this.score &&
          other.semanticSimilarity == this.semanticSimilarity &&
          other.keywordMatch == this.keywordMatch &&
          other.isCorrect == this.isCorrect &&
          other.feedback == this.feedback &&
          other.missingKeywords == this.missingKeywords &&
          other.evaluatedAt == this.evaluatedAt);
}

class EvaluationsCompanion extends UpdateCompanion<Evaluation> {
  final Value<int> id;
  final Value<String> questionId;
  final Value<String> studentAnswer;
  final Value<double> score;
  final Value<double> semanticSimilarity;
  final Value<double> keywordMatch;
  final Value<bool> isCorrect;
  final Value<String?> feedback;
  final Value<String?> missingKeywords;
  final Value<DateTime> evaluatedAt;
  const EvaluationsCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.studentAnswer = const Value.absent(),
    this.score = const Value.absent(),
    this.semanticSimilarity = const Value.absent(),
    this.keywordMatch = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.feedback = const Value.absent(),
    this.missingKeywords = const Value.absent(),
    this.evaluatedAt = const Value.absent(),
  });
  EvaluationsCompanion.insert({
    this.id = const Value.absent(),
    required String questionId,
    required String studentAnswer,
    required double score,
    required double semanticSimilarity,
    required double keywordMatch,
    required bool isCorrect,
    this.feedback = const Value.absent(),
    this.missingKeywords = const Value.absent(),
    required DateTime evaluatedAt,
  }) : questionId = Value(questionId),
       studentAnswer = Value(studentAnswer),
       score = Value(score),
       semanticSimilarity = Value(semanticSimilarity),
       keywordMatch = Value(keywordMatch),
       isCorrect = Value(isCorrect),
       evaluatedAt = Value(evaluatedAt);
  static Insertable<Evaluation> custom({
    Expression<int>? id,
    Expression<String>? questionId,
    Expression<String>? studentAnswer,
    Expression<double>? score,
    Expression<double>? semanticSimilarity,
    Expression<double>? keywordMatch,
    Expression<bool>? isCorrect,
    Expression<String>? feedback,
    Expression<String>? missingKeywords,
    Expression<DateTime>? evaluatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (studentAnswer != null) 'student_answer': studentAnswer,
      if (score != null) 'score': score,
      if (semanticSimilarity != null) 'semantic_similarity': semanticSimilarity,
      if (keywordMatch != null) 'keyword_match': keywordMatch,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (feedback != null) 'feedback': feedback,
      if (missingKeywords != null) 'missing_keywords': missingKeywords,
      if (evaluatedAt != null) 'evaluated_at': evaluatedAt,
    });
  }

  EvaluationsCompanion copyWith({
    Value<int>? id,
    Value<String>? questionId,
    Value<String>? studentAnswer,
    Value<double>? score,
    Value<double>? semanticSimilarity,
    Value<double>? keywordMatch,
    Value<bool>? isCorrect,
    Value<String?>? feedback,
    Value<String?>? missingKeywords,
    Value<DateTime>? evaluatedAt,
  }) {
    return EvaluationsCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      studentAnswer: studentAnswer ?? this.studentAnswer,
      score: score ?? this.score,
      semanticSimilarity: semanticSimilarity ?? this.semanticSimilarity,
      keywordMatch: keywordMatch ?? this.keywordMatch,
      isCorrect: isCorrect ?? this.isCorrect,
      feedback: feedback ?? this.feedback,
      missingKeywords: missingKeywords ?? this.missingKeywords,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (studentAnswer.present) {
      map['student_answer'] = Variable<String>(studentAnswer.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (semanticSimilarity.present) {
      map['semantic_similarity'] = Variable<double>(semanticSimilarity.value);
    }
    if (keywordMatch.present) {
      map['keyword_match'] = Variable<double>(keywordMatch.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (feedback.present) {
      map['feedback'] = Variable<String>(feedback.value);
    }
    if (missingKeywords.present) {
      map['missing_keywords'] = Variable<String>(missingKeywords.value);
    }
    if (evaluatedAt.present) {
      map['evaluated_at'] = Variable<DateTime>(evaluatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvaluationsCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('studentAnswer: $studentAnswer, ')
          ..write('score: $score, ')
          ..write('semanticSimilarity: $semanticSimilarity, ')
          ..write('keywordMatch: $keywordMatch, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('feedback: $feedback, ')
          ..write('missingKeywords: $missingKeywords, ')
          ..write('evaluatedAt: $evaluatedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncWatermarksTable extends SyncWatermarks
    with TableInfo<$SyncWatermarksTable, SyncWatermark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncWatermarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _remoteTableMeta = const VerificationMeta(
    'remoteTable',
  );
  @override
  late final GeneratedColumn<String> remoteTable = GeneratedColumn<String>(
    'remote_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [remoteTable, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_watermarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncWatermark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('remote_table')) {
      context.handle(
        _remoteTableMeta,
        remoteTable.isAcceptableOrUnknown(
          data['remote_table']!,
          _remoteTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteTableMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {remoteTable};
  @override
  SyncWatermark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncWatermark(
      remoteTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_table'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      )!,
    );
  }

  @override
  $SyncWatermarksTable createAlias(String alias) {
    return $SyncWatermarksTable(attachedDatabase, alias);
  }
}

class SyncWatermark extends DataClass implements Insertable<SyncWatermark> {
  final String remoteTable;
  final DateTime lastSyncedAt;
  const SyncWatermark({required this.remoteTable, required this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['remote_table'] = Variable<String>(remoteTable);
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    return map;
  }

  SyncWatermarksCompanion toCompanion(bool nullToAbsent) {
    return SyncWatermarksCompanion(
      remoteTable: Value(remoteTable),
      lastSyncedAt: Value(lastSyncedAt),
    );
  }

  factory SyncWatermark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncWatermark(
      remoteTable: serializer.fromJson<String>(json['remoteTable']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'remoteTable': serializer.toJson<String>(remoteTable),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
    };
  }

  SyncWatermark copyWith({String? remoteTable, DateTime? lastSyncedAt}) =>
      SyncWatermark(
        remoteTable: remoteTable ?? this.remoteTable,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
  SyncWatermark copyWithCompanion(SyncWatermarksCompanion data) {
    return SyncWatermark(
      remoteTable: data.remoteTable.present
          ? data.remoteTable.value
          : this.remoteTable,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncWatermark(')
          ..write('remoteTable: $remoteTable, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(remoteTable, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncWatermark &&
          other.remoteTable == this.remoteTable &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncWatermarksCompanion extends UpdateCompanion<SyncWatermark> {
  final Value<String> remoteTable;
  final Value<DateTime> lastSyncedAt;
  final Value<int> rowid;
  const SyncWatermarksCompanion({
    this.remoteTable = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncWatermarksCompanion.insert({
    required String remoteTable,
    required DateTime lastSyncedAt,
    this.rowid = const Value.absent(),
  }) : remoteTable = Value(remoteTable),
       lastSyncedAt = Value(lastSyncedAt);
  static Insertable<SyncWatermark> custom({
    Expression<String>? remoteTable,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (remoteTable != null) 'remote_table': remoteTable,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncWatermarksCompanion copyWith({
    Value<String>? remoteTable,
    Value<DateTime>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return SyncWatermarksCompanion(
      remoteTable: remoteTable ?? this.remoteTable,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (remoteTable.present) {
      map['remote_table'] = Variable<String>(remoteTable.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncWatermarksCompanion(')
          ..write('remoteTable: $remoteTable, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpacedRepetitionTable extends SpacedRepetition
    with TableInfo<$SpacedRepetitionTable, SpacedRepetitionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpacedRepetitionTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boxMeta = const VerificationMeta('box');
  @override
  late final GeneratedColumn<int> box = GeneratedColumn<int>(
    'box',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    questionId,
    box,
    easeFactor,
    intervalDays,
    repetitions,
    lapses,
    dueAt,
    lastReviewedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spaced_repetition';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpacedRepetitionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('box')) {
      context.handle(
        _boxMeta,
        box.isAcceptableOrUnknown(data['box']!, _boxMeta),
      );
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionId};
  @override
  SpacedRepetitionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpacedRepetitionData(
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      box: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $SpacedRepetitionTable createAlias(String alias) {
    return $SpacedRepetitionTable(attachedDatabase, alias);
  }
}

class SpacedRepetitionData extends DataClass
    implements Insertable<SpacedRepetitionData> {
  final String questionId;
  final int box;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final int lapses;
  final DateTime dueAt;
  final DateTime? lastReviewedAt;
  final DateTime? updatedAt;
  const SpacedRepetitionData({
    required this.questionId,
    required this.box,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.lapses,
    required this.dueAt,
    this.lastReviewedAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_id'] = Variable<String>(questionId);
    map['box'] = Variable<int>(box);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    map['lapses'] = Variable<int>(lapses);
    map['due_at'] = Variable<DateTime>(dueAt);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  SpacedRepetitionCompanion toCompanion(bool nullToAbsent) {
    return SpacedRepetitionCompanion(
      questionId: Value(questionId),
      box: Value(box),
      easeFactor: Value(easeFactor),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      lapses: Value(lapses),
      dueAt: Value(dueAt),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory SpacedRepetitionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpacedRepetitionData(
      questionId: serializer.fromJson<String>(json['questionId']),
      box: serializer.fromJson<int>(json['box']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      lapses: serializer.fromJson<int>(json['lapses']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionId': serializer.toJson<String>(questionId),
      'box': serializer.toJson<int>(box),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'lapses': serializer.toJson<int>(lapses),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  SpacedRepetitionData copyWith({
    String? questionId,
    int? box,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    int? lapses,
    DateTime? dueAt,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => SpacedRepetitionData(
    questionId: questionId ?? this.questionId,
    box: box ?? this.box,
    easeFactor: easeFactor ?? this.easeFactor,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    lapses: lapses ?? this.lapses,
    dueAt: dueAt ?? this.dueAt,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  SpacedRepetitionData copyWithCompanion(SpacedRepetitionCompanion data) {
    return SpacedRepetitionData(
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      box: data.box.present ? data.box.value : this.box,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpacedRepetitionData(')
          ..write('questionId: $questionId, ')
          ..write('box: $box, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    questionId,
    box,
    easeFactor,
    intervalDays,
    repetitions,
    lapses,
    dueAt,
    lastReviewedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpacedRepetitionData &&
          other.questionId == this.questionId &&
          other.box == this.box &&
          other.easeFactor == this.easeFactor &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.lapses == this.lapses &&
          other.dueAt == this.dueAt &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.updatedAt == this.updatedAt);
}

class SpacedRepetitionCompanion extends UpdateCompanion<SpacedRepetitionData> {
  final Value<String> questionId;
  final Value<int> box;
  final Value<double> easeFactor;
  final Value<int> intervalDays;
  final Value<int> repetitions;
  final Value<int> lapses;
  final Value<DateTime> dueAt;
  final Value<DateTime?> lastReviewedAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const SpacedRepetitionCompanion({
    this.questionId = const Value.absent(),
    this.box = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SpacedRepetitionCompanion.insert({
    required String questionId,
    this.box = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    required DateTime dueAt,
    this.lastReviewedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : questionId = Value(questionId),
       dueAt = Value(dueAt);
  static Insertable<SpacedRepetitionData> custom({
    Expression<String>? questionId,
    Expression<int>? box,
    Expression<double>? easeFactor,
    Expression<int>? intervalDays,
    Expression<int>? repetitions,
    Expression<int>? lapses,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? lastReviewedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionId != null) 'question_id': questionId,
      if (box != null) 'box': box,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (lapses != null) 'lapses': lapses,
      if (dueAt != null) 'due_at': dueAt,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SpacedRepetitionCompanion copyWith({
    Value<String>? questionId,
    Value<int>? box,
    Value<double>? easeFactor,
    Value<int>? intervalDays,
    Value<int>? repetitions,
    Value<int>? lapses,
    Value<DateTime>? dueAt,
    Value<DateTime?>? lastReviewedAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return SpacedRepetitionCompanion(
      questionId: questionId ?? this.questionId,
      box: box ?? this.box,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (box.present) {
      map['box'] = Variable<int>(box.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpacedRepetitionCompanion(')
          ..write('questionId: $questionId, ')
          ..write('box: $box, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FlashcardsTable extends Flashcards
    with TableInfo<$FlashcardsTable, Flashcard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlashcardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frontMeta = const VerificationMeta('front');
  @override
  late final GeneratedColumn<String> front = GeneratedColumn<String>(
    'front',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backMeta = const VerificationMeta('back');
  @override
  late final GeneratedColumn<String> back = GeneratedColumn<String>(
    'back',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ncertReferenceMeta = const VerificationMeta(
    'ncertReference',
  );
  @override
  late final GeneratedColumn<String> ncertReference = GeneratedColumn<String>(
    'ncert_reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourcePageMeta = const VerificationMeta(
    'sourcePage',
  );
  @override
  late final GeneratedColumn<int> sourcePage = GeneratedColumn<int>(
    'source_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Medium'),
  );
  static const VerificationMeta _isGeneratedMeta = const VerificationMeta(
    'isGenerated',
  );
  @override
  late final GeneratedColumn<bool> isGenerated = GeneratedColumn<bool>(
    'is_generated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_generated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _boxMeta = const VerificationMeta('box');
  @override
  late final GeneratedColumn<int> box = GeneratedColumn<int>(
    'box',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    front,
    back,
    subject,
    topicId,
    imageUrl,
    chapterId,
    ncertReference,
    sourcePage,
    difficulty,
    isGenerated,
    box,
    easeFactor,
    intervalDays,
    repetitions,
    lapses,
    dueAt,
    lastReviewedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flashcards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Flashcard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('front')) {
      context.handle(
        _frontMeta,
        front.isAcceptableOrUnknown(data['front']!, _frontMeta),
      );
    } else if (isInserting) {
      context.missing(_frontMeta);
    }
    if (data.containsKey('back')) {
      context.handle(
        _backMeta,
        back.isAcceptableOrUnknown(data['back']!, _backMeta),
      );
    } else if (isInserting) {
      context.missing(_backMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    }
    if (data.containsKey('ncert_reference')) {
      context.handle(
        _ncertReferenceMeta,
        ncertReference.isAcceptableOrUnknown(
          data['ncert_reference']!,
          _ncertReferenceMeta,
        ),
      );
    }
    if (data.containsKey('source_page')) {
      context.handle(
        _sourcePageMeta,
        sourcePage.isAcceptableOrUnknown(data['source_page']!, _sourcePageMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('is_generated')) {
      context.handle(
        _isGeneratedMeta,
        isGenerated.isAcceptableOrUnknown(
          data['is_generated']!,
          _isGeneratedMeta,
        ),
      );
    }
    if (data.containsKey('box')) {
      context.handle(
        _boxMeta,
        box.isAcceptableOrUnknown(data['box']!, _boxMeta),
      );
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Flashcard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Flashcard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      front: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front'],
      )!,
      back: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_id'],
      )!,
      ncertReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ncert_reference'],
      )!,
      sourcePage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_page'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      isGenerated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_generated'],
      )!,
      box: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $FlashcardsTable createAlias(String alias) {
    return $FlashcardsTable(attachedDatabase, alias);
  }
}

class Flashcard extends DataClass implements Insertable<Flashcard> {
  final String id;
  final String front;
  final String back;
  final String subject;
  final String topicId;
  final String? imageUrl;
  final String chapterId;
  final String ncertReference;
  final int sourcePage;
  final String difficulty;
  final bool isGenerated;
  final int box;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final int lapses;
  final DateTime dueAt;
  final DateTime? lastReviewedAt;
  final DateTime? createdAt;
  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    required this.subject,
    required this.topicId,
    this.imageUrl,
    required this.chapterId,
    required this.ncertReference,
    required this.sourcePage,
    required this.difficulty,
    required this.isGenerated,
    required this.box,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.lapses,
    required this.dueAt,
    this.lastReviewedAt,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['front'] = Variable<String>(front);
    map['back'] = Variable<String>(back);
    map['subject'] = Variable<String>(subject);
    map['topic_id'] = Variable<String>(topicId);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['chapter_id'] = Variable<String>(chapterId);
    map['ncert_reference'] = Variable<String>(ncertReference);
    map['source_page'] = Variable<int>(sourcePage);
    map['difficulty'] = Variable<String>(difficulty);
    map['is_generated'] = Variable<bool>(isGenerated);
    map['box'] = Variable<int>(box);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    map['lapses'] = Variable<int>(lapses);
    map['due_at'] = Variable<DateTime>(dueAt);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  FlashcardsCompanion toCompanion(bool nullToAbsent) {
    return FlashcardsCompanion(
      id: Value(id),
      front: Value(front),
      back: Value(back),
      subject: Value(subject),
      topicId: Value(topicId),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      chapterId: Value(chapterId),
      ncertReference: Value(ncertReference),
      sourcePage: Value(sourcePage),
      difficulty: Value(difficulty),
      isGenerated: Value(isGenerated),
      box: Value(box),
      easeFactor: Value(easeFactor),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      lapses: Value(lapses),
      dueAt: Value(dueAt),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Flashcard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Flashcard(
      id: serializer.fromJson<String>(json['id']),
      front: serializer.fromJson<String>(json['front']),
      back: serializer.fromJson<String>(json['back']),
      subject: serializer.fromJson<String>(json['subject']),
      topicId: serializer.fromJson<String>(json['topicId']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      ncertReference: serializer.fromJson<String>(json['ncertReference']),
      sourcePage: serializer.fromJson<int>(json['sourcePage']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      isGenerated: serializer.fromJson<bool>(json['isGenerated']),
      box: serializer.fromJson<int>(json['box']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      lapses: serializer.fromJson<int>(json['lapses']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'front': serializer.toJson<String>(front),
      'back': serializer.toJson<String>(back),
      'subject': serializer.toJson<String>(subject),
      'topicId': serializer.toJson<String>(topicId),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'chapterId': serializer.toJson<String>(chapterId),
      'ncertReference': serializer.toJson<String>(ncertReference),
      'sourcePage': serializer.toJson<int>(sourcePage),
      'difficulty': serializer.toJson<String>(difficulty),
      'isGenerated': serializer.toJson<bool>(isGenerated),
      'box': serializer.toJson<int>(box),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'lapses': serializer.toJson<int>(lapses),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  Flashcard copyWith({
    String? id,
    String? front,
    String? back,
    String? subject,
    String? topicId,
    Value<String?> imageUrl = const Value.absent(),
    String? chapterId,
    String? ncertReference,
    int? sourcePage,
    String? difficulty,
    bool? isGenerated,
    int? box,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    int? lapses,
    DateTime? dueAt,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
  }) => Flashcard(
    id: id ?? this.id,
    front: front ?? this.front,
    back: back ?? this.back,
    subject: subject ?? this.subject,
    topicId: topicId ?? this.topicId,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    chapterId: chapterId ?? this.chapterId,
    ncertReference: ncertReference ?? this.ncertReference,
    sourcePage: sourcePage ?? this.sourcePage,
    difficulty: difficulty ?? this.difficulty,
    isGenerated: isGenerated ?? this.isGenerated,
    box: box ?? this.box,
    easeFactor: easeFactor ?? this.easeFactor,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    lapses: lapses ?? this.lapses,
    dueAt: dueAt ?? this.dueAt,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Flashcard copyWithCompanion(FlashcardsCompanion data) {
    return Flashcard(
      id: data.id.present ? data.id.value : this.id,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
      subject: data.subject.present ? data.subject.value : this.subject,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      ncertReference: data.ncertReference.present
          ? data.ncertReference.value
          : this.ncertReference,
      sourcePage: data.sourcePage.present
          ? data.sourcePage.value
          : this.sourcePage,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      isGenerated: data.isGenerated.present
          ? data.isGenerated.value
          : this.isGenerated,
      box: data.box.present ? data.box.value : this.box,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Flashcard(')
          ..write('id: $id, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('subject: $subject, ')
          ..write('topicId: $topicId, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('chapterId: $chapterId, ')
          ..write('ncertReference: $ncertReference, ')
          ..write('sourcePage: $sourcePage, ')
          ..write('difficulty: $difficulty, ')
          ..write('isGenerated: $isGenerated, ')
          ..write('box: $box, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    front,
    back,
    subject,
    topicId,
    imageUrl,
    chapterId,
    ncertReference,
    sourcePage,
    difficulty,
    isGenerated,
    box,
    easeFactor,
    intervalDays,
    repetitions,
    lapses,
    dueAt,
    lastReviewedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Flashcard &&
          other.id == this.id &&
          other.front == this.front &&
          other.back == this.back &&
          other.subject == this.subject &&
          other.topicId == this.topicId &&
          other.imageUrl == this.imageUrl &&
          other.chapterId == this.chapterId &&
          other.ncertReference == this.ncertReference &&
          other.sourcePage == this.sourcePage &&
          other.difficulty == this.difficulty &&
          other.isGenerated == this.isGenerated &&
          other.box == this.box &&
          other.easeFactor == this.easeFactor &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.lapses == this.lapses &&
          other.dueAt == this.dueAt &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.createdAt == this.createdAt);
}

class FlashcardsCompanion extends UpdateCompanion<Flashcard> {
  final Value<String> id;
  final Value<String> front;
  final Value<String> back;
  final Value<String> subject;
  final Value<String> topicId;
  final Value<String?> imageUrl;
  final Value<String> chapterId;
  final Value<String> ncertReference;
  final Value<int> sourcePage;
  final Value<String> difficulty;
  final Value<bool> isGenerated;
  final Value<int> box;
  final Value<double> easeFactor;
  final Value<int> intervalDays;
  final Value<int> repetitions;
  final Value<int> lapses;
  final Value<DateTime> dueAt;
  final Value<DateTime?> lastReviewedAt;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const FlashcardsCompanion({
    this.id = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.subject = const Value.absent(),
    this.topicId = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.ncertReference = const Value.absent(),
    this.sourcePage = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.isGenerated = const Value.absent(),
    this.box = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FlashcardsCompanion.insert({
    required String id,
    required String front,
    required String back,
    required String subject,
    this.topicId = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.ncertReference = const Value.absent(),
    this.sourcePage = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.isGenerated = const Value.absent(),
    this.box = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    required DateTime dueAt,
    this.lastReviewedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       front = Value(front),
       back = Value(back),
       subject = Value(subject),
       dueAt = Value(dueAt);
  static Insertable<Flashcard> custom({
    Expression<String>? id,
    Expression<String>? front,
    Expression<String>? back,
    Expression<String>? subject,
    Expression<String>? topicId,
    Expression<String>? imageUrl,
    Expression<String>? chapterId,
    Expression<String>? ncertReference,
    Expression<int>? sourcePage,
    Expression<String>? difficulty,
    Expression<bool>? isGenerated,
    Expression<int>? box,
    Expression<double>? easeFactor,
    Expression<int>? intervalDays,
    Expression<int>? repetitions,
    Expression<int>? lapses,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? lastReviewedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
      if (subject != null) 'subject': subject,
      if (topicId != null) 'topic_id': topicId,
      if (imageUrl != null) 'image_url': imageUrl,
      if (chapterId != null) 'chapter_id': chapterId,
      if (ncertReference != null) 'ncert_reference': ncertReference,
      if (sourcePage != null) 'source_page': sourcePage,
      if (difficulty != null) 'difficulty': difficulty,
      if (isGenerated != null) 'is_generated': isGenerated,
      if (box != null) 'box': box,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (lapses != null) 'lapses': lapses,
      if (dueAt != null) 'due_at': dueAt,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FlashcardsCompanion copyWith({
    Value<String>? id,
    Value<String>? front,
    Value<String>? back,
    Value<String>? subject,
    Value<String>? topicId,
    Value<String?>? imageUrl,
    Value<String>? chapterId,
    Value<String>? ncertReference,
    Value<int>? sourcePage,
    Value<String>? difficulty,
    Value<bool>? isGenerated,
    Value<int>? box,
    Value<double>? easeFactor,
    Value<int>? intervalDays,
    Value<int>? repetitions,
    Value<int>? lapses,
    Value<DateTime>? dueAt,
    Value<DateTime?>? lastReviewedAt,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return FlashcardsCompanion(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      subject: subject ?? this.subject,
      topicId: topicId ?? this.topicId,
      imageUrl: imageUrl ?? this.imageUrl,
      chapterId: chapterId ?? this.chapterId,
      ncertReference: ncertReference ?? this.ncertReference,
      sourcePage: sourcePage ?? this.sourcePage,
      difficulty: difficulty ?? this.difficulty,
      isGenerated: isGenerated ?? this.isGenerated,
      box: box ?? this.box,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (front.present) {
      map['front'] = Variable<String>(front.value);
    }
    if (back.present) {
      map['back'] = Variable<String>(back.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (ncertReference.present) {
      map['ncert_reference'] = Variable<String>(ncertReference.value);
    }
    if (sourcePage.present) {
      map['source_page'] = Variable<int>(sourcePage.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (isGenerated.present) {
      map['is_generated'] = Variable<bool>(isGenerated.value);
    }
    if (box.present) {
      map['box'] = Variable<int>(box.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardsCompanion(')
          ..write('id: $id, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('subject: $subject, ')
          ..write('topicId: $topicId, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('chapterId: $chapterId, ')
          ..write('ncertReference: $ncertReference, ')
          ..write('sourcePage: $sourcePage, ')
          ..write('difficulty: $difficulty, ')
          ..write('isGenerated: $isGenerated, ')
          ..write('box: $box, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DppSetsTable extends DppSets with TableInfo<$DppSetsTable, DppSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DppSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
    'chapter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalQuestionsMeta = const VerificationMeta(
    'totalQuestions',
  );
  @override
  late final GeneratedColumn<int> totalQuestions = GeneratedColumn<int>(
    'total_questions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _incorrectCountMeta = const VerificationMeta(
    'incorrectCount',
  );
  @override
  late final GeneratedColumn<int> incorrectCount = GeneratedColumn<int>(
    'incorrect_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unattemptedCountMeta = const VerificationMeta(
    'unattemptedCount',
  );
  @override
  late final GeneratedColumn<int> unattemptedCount = GeneratedColumn<int>(
    'unattempted_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timeSpentSecondsMeta = const VerificationMeta(
    'timeSpentSeconds',
  );
  @override
  late final GeneratedColumn<int> timeSpentSeconds = GeneratedColumn<int>(
    'time_spent_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    subject,
    chapterId,
    topicId,
    totalQuestions,
    durationMinutes,
    correctCount,
    incorrectCount,
    unattemptedCount,
    timeSpentSeconds,
    isCompleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dpp_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<DppSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    }
    if (data.containsKey('total_questions')) {
      context.handle(
        _totalQuestionsMeta,
        totalQuestions.isAcceptableOrUnknown(
          data['total_questions']!,
          _totalQuestionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalQuestionsMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('incorrect_count')) {
      context.handle(
        _incorrectCountMeta,
        incorrectCount.isAcceptableOrUnknown(
          data['incorrect_count']!,
          _incorrectCountMeta,
        ),
      );
    }
    if (data.containsKey('unattempted_count')) {
      context.handle(
        _unattemptedCountMeta,
        unattemptedCount.isAcceptableOrUnknown(
          data['unattempted_count']!,
          _unattemptedCountMeta,
        ),
      );
    }
    if (data.containsKey('time_spent_seconds')) {
      context.handle(
        _timeSpentSecondsMeta,
        timeSpentSeconds.isAcceptableOrUnknown(
          data['time_spent_seconds']!,
          _timeSpentSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DppSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DppSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_id'],
      ),
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      ),
      totalQuestions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_questions'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      incorrectCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}incorrect_count'],
      )!,
      unattemptedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unattempted_count'],
      )!,
      timeSpentSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_spent_seconds'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $DppSetsTable createAlias(String alias) {
    return $DppSetsTable(attachedDatabase, alias);
  }
}

class DppSet extends DataClass implements Insertable<DppSet> {
  final int id;
  final String date;
  final String subject;
  final String? chapterId;
  final String? topicId;
  final int totalQuestions;
  final int? durationMinutes;
  final int correctCount;
  final int incorrectCount;
  final int unattemptedCount;
  final int timeSpentSeconds;
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const DppSet({
    required this.id,
    required this.date,
    required this.subject,
    this.chapterId,
    this.topicId,
    required this.totalQuestions,
    this.durationMinutes,
    required this.correctCount,
    required this.incorrectCount,
    required this.unattemptedCount,
    required this.timeSpentSeconds,
    required this.isCompleted,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['subject'] = Variable<String>(subject);
    if (!nullToAbsent || chapterId != null) {
      map['chapter_id'] = Variable<String>(chapterId);
    }
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<String>(topicId);
    }
    map['total_questions'] = Variable<int>(totalQuestions);
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    map['correct_count'] = Variable<int>(correctCount);
    map['incorrect_count'] = Variable<int>(incorrectCount);
    map['unattempted_count'] = Variable<int>(unattemptedCount);
    map['time_spent_seconds'] = Variable<int>(timeSpentSeconds);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  DppSetsCompanion toCompanion(bool nullToAbsent) {
    return DppSetsCompanion(
      id: Value(id),
      date: Value(date),
      subject: Value(subject),
      chapterId: chapterId == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterId),
      topicId: topicId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicId),
      totalQuestions: Value(totalQuestions),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      correctCount: Value(correctCount),
      incorrectCount: Value(incorrectCount),
      unattemptedCount: Value(unattemptedCount),
      timeSpentSeconds: Value(timeSpentSeconds),
      isCompleted: Value(isCompleted),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory DppSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DppSet(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      subject: serializer.fromJson<String>(json['subject']),
      chapterId: serializer.fromJson<String?>(json['chapterId']),
      topicId: serializer.fromJson<String?>(json['topicId']),
      totalQuestions: serializer.fromJson<int>(json['totalQuestions']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      incorrectCount: serializer.fromJson<int>(json['incorrectCount']),
      unattemptedCount: serializer.fromJson<int>(json['unattemptedCount']),
      timeSpentSeconds: serializer.fromJson<int>(json['timeSpentSeconds']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'subject': serializer.toJson<String>(subject),
      'chapterId': serializer.toJson<String?>(chapterId),
      'topicId': serializer.toJson<String?>(topicId),
      'totalQuestions': serializer.toJson<int>(totalQuestions),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'correctCount': serializer.toJson<int>(correctCount),
      'incorrectCount': serializer.toJson<int>(incorrectCount),
      'unattemptedCount': serializer.toJson<int>(unattemptedCount),
      'timeSpentSeconds': serializer.toJson<int>(timeSpentSeconds),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  DppSet copyWith({
    int? id,
    String? date,
    String? subject,
    Value<String?> chapterId = const Value.absent(),
    Value<String?> topicId = const Value.absent(),
    int? totalQuestions,
    Value<int?> durationMinutes = const Value.absent(),
    int? correctCount,
    int? incorrectCount,
    int? unattemptedCount,
    int? timeSpentSeconds,
    bool? isCompleted,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => DppSet(
    id: id ?? this.id,
    date: date ?? this.date,
    subject: subject ?? this.subject,
    chapterId: chapterId.present ? chapterId.value : this.chapterId,
    topicId: topicId.present ? topicId.value : this.topicId,
    totalQuestions: totalQuestions ?? this.totalQuestions,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    correctCount: correctCount ?? this.correctCount,
    incorrectCount: incorrectCount ?? this.incorrectCount,
    unattemptedCount: unattemptedCount ?? this.unattemptedCount,
    timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  DppSet copyWithCompanion(DppSetsCompanion data) {
    return DppSet(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      subject: data.subject.present ? data.subject.value : this.subject,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      totalQuestions: data.totalQuestions.present
          ? data.totalQuestions.value
          : this.totalQuestions,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      incorrectCount: data.incorrectCount.present
          ? data.incorrectCount.value
          : this.incorrectCount,
      unattemptedCount: data.unattemptedCount.present
          ? data.unattemptedCount.value
          : this.unattemptedCount,
      timeSpentSeconds: data.timeSpentSeconds.present
          ? data.timeSpentSeconds.value
          : this.timeSpentSeconds,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DppSet(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('subject: $subject, ')
          ..write('chapterId: $chapterId, ')
          ..write('topicId: $topicId, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('unattemptedCount: $unattemptedCount, ')
          ..write('timeSpentSeconds: $timeSpentSeconds, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    subject,
    chapterId,
    topicId,
    totalQuestions,
    durationMinutes,
    correctCount,
    incorrectCount,
    unattemptedCount,
    timeSpentSeconds,
    isCompleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DppSet &&
          other.id == this.id &&
          other.date == this.date &&
          other.subject == this.subject &&
          other.chapterId == this.chapterId &&
          other.topicId == this.topicId &&
          other.totalQuestions == this.totalQuestions &&
          other.durationMinutes == this.durationMinutes &&
          other.correctCount == this.correctCount &&
          other.incorrectCount == this.incorrectCount &&
          other.unattemptedCount == this.unattemptedCount &&
          other.timeSpentSeconds == this.timeSpentSeconds &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DppSetsCompanion extends UpdateCompanion<DppSet> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> subject;
  final Value<String?> chapterId;
  final Value<String?> topicId;
  final Value<int> totalQuestions;
  final Value<int?> durationMinutes;
  final Value<int> correctCount;
  final Value<int> incorrectCount;
  final Value<int> unattemptedCount;
  final Value<int> timeSpentSeconds;
  final Value<bool> isCompleted;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  const DppSetsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.subject = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.unattemptedCount = const Value.absent(),
    this.timeSpentSeconds = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DppSetsCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String subject,
    this.chapterId = const Value.absent(),
    this.topicId = const Value.absent(),
    required int totalQuestions,
    this.durationMinutes = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.unattemptedCount = const Value.absent(),
    this.timeSpentSeconds = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : date = Value(date),
       subject = Value(subject),
       totalQuestions = Value(totalQuestions);
  static Insertable<DppSet> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? subject,
    Expression<String>? chapterId,
    Expression<String>? topicId,
    Expression<int>? totalQuestions,
    Expression<int>? durationMinutes,
    Expression<int>? correctCount,
    Expression<int>? incorrectCount,
    Expression<int>? unattemptedCount,
    Expression<int>? timeSpentSeconds,
    Expression<bool>? isCompleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (subject != null) 'subject': subject,
      if (chapterId != null) 'chapter_id': chapterId,
      if (topicId != null) 'topic_id': topicId,
      if (totalQuestions != null) 'total_questions': totalQuestions,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (correctCount != null) 'correct_count': correctCount,
      if (incorrectCount != null) 'incorrect_count': incorrectCount,
      if (unattemptedCount != null) 'unattempted_count': unattemptedCount,
      if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DppSetsCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String>? subject,
    Value<String?>? chapterId,
    Value<String?>? topicId,
    Value<int>? totalQuestions,
    Value<int?>? durationMinutes,
    Value<int>? correctCount,
    Value<int>? incorrectCount,
    Value<int>? unattemptedCount,
    Value<int>? timeSpentSeconds,
    Value<bool>? isCompleted,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
  }) {
    return DppSetsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      subject: subject ?? this.subject,
      chapterId: chapterId ?? this.chapterId,
      topicId: topicId ?? this.topicId,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      unattemptedCount: unattemptedCount ?? this.unattemptedCount,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (totalQuestions.present) {
      map['total_questions'] = Variable<int>(totalQuestions.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (incorrectCount.present) {
      map['incorrect_count'] = Variable<int>(incorrectCount.value);
    }
    if (unattemptedCount.present) {
      map['unattempted_count'] = Variable<int>(unattemptedCount.value);
    }
    if (timeSpentSeconds.present) {
      map['time_spent_seconds'] = Variable<int>(timeSpentSeconds.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DppSetsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('subject: $subject, ')
          ..write('chapterId: $chapterId, ')
          ..write('topicId: $topicId, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('unattemptedCount: $unattemptedCount, ')
          ..write('timeSpentSeconds: $timeSpentSeconds, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DppQuestionsTable extends DppQuestions
    with TableInfo<$DppQuestionsTable, DppQuestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DppQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dppSetIdMeta = const VerificationMeta(
    'dppSetId',
  );
  @override
  late final GeneratedColumn<int> dppSetId = GeneratedColumn<int>(
    'dpp_set_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<String> chapter = GeneratedColumn<String>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionTextMeta = const VerificationMeta(
    'questionText',
  );
  @override
  late final GeneratedColumn<String> questionText = GeneratedColumn<String>(
    'question_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'options',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctAnswerMeta = const VerificationMeta(
    'correctAnswer',
  );
  @override
  late final GeneratedColumn<String> correctAnswer = GeneratedColumn<String>(
    'correct_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dpp'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dppSetId,
    questionId,
    subject,
    chapter,
    topic,
    topicId,
    difficulty,
    questionText,
    options,
    correctAnswer,
    explanation,
    year,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dpp_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DppQuestion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dpp_set_id')) {
      context.handle(
        _dppSetIdMeta,
        dppSetId.isAcceptableOrUnknown(data['dpp_set_id']!, _dppSetIdMeta),
      );
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('question_text')) {
      context.handle(
        _questionTextMeta,
        questionText.isAcceptableOrUnknown(
          data['question_text']!,
          _questionTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionTextMeta);
    }
    if (data.containsKey('options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['options']!, _optionsMeta),
      );
    } else if (isInserting) {
      context.missing(_optionsMeta);
    }
    if (data.containsKey('correct_answer')) {
      context.handle(
        _correctAnswerMeta,
        correctAnswer.isAcceptableOrUnknown(
          data['correct_answer']!,
          _correctAnswerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctAnswerMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DppQuestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DppQuestion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dppSetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dpp_set_id'],
      ),
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      questionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_text'],
      )!,
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options'],
      )!,
      correctAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correct_answer'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $DppQuestionsTable createAlias(String alias) {
    return $DppQuestionsTable(attachedDatabase, alias);
  }
}

class DppQuestion extends DataClass implements Insertable<DppQuestion> {
  final int id;
  final int? dppSetId;
  final String questionId;
  final String subject;
  final String chapter;
  final String topic;
  final String topicId;
  final String difficulty;
  final String questionText;
  final String options;
  final String correctAnswer;
  final String? explanation;
  final int? year;
  final String source;
  const DppQuestion({
    required this.id,
    this.dppSetId,
    required this.questionId,
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.topicId,
    required this.difficulty,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.year,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || dppSetId != null) {
      map['dpp_set_id'] = Variable<int>(dppSetId);
    }
    map['question_id'] = Variable<String>(questionId);
    map['subject'] = Variable<String>(subject);
    map['chapter'] = Variable<String>(chapter);
    map['topic'] = Variable<String>(topic);
    map['topic_id'] = Variable<String>(topicId);
    map['difficulty'] = Variable<String>(difficulty);
    map['question_text'] = Variable<String>(questionText);
    map['options'] = Variable<String>(options);
    map['correct_answer'] = Variable<String>(correctAnswer);
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['source'] = Variable<String>(source);
    return map;
  }

  DppQuestionsCompanion toCompanion(bool nullToAbsent) {
    return DppQuestionsCompanion(
      id: Value(id),
      dppSetId: dppSetId == null && nullToAbsent
          ? const Value.absent()
          : Value(dppSetId),
      questionId: Value(questionId),
      subject: Value(subject),
      chapter: Value(chapter),
      topic: Value(topic),
      topicId: Value(topicId),
      difficulty: Value(difficulty),
      questionText: Value(questionText),
      options: Value(options),
      correctAnswer: Value(correctAnswer),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      source: Value(source),
    );
  }

  factory DppQuestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DppQuestion(
      id: serializer.fromJson<int>(json['id']),
      dppSetId: serializer.fromJson<int?>(json['dppSetId']),
      questionId: serializer.fromJson<String>(json['questionId']),
      subject: serializer.fromJson<String>(json['subject']),
      chapter: serializer.fromJson<String>(json['chapter']),
      topic: serializer.fromJson<String>(json['topic']),
      topicId: serializer.fromJson<String>(json['topicId']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      questionText: serializer.fromJson<String>(json['questionText']),
      options: serializer.fromJson<String>(json['options']),
      correctAnswer: serializer.fromJson<String>(json['correctAnswer']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      year: serializer.fromJson<int?>(json['year']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dppSetId': serializer.toJson<int?>(dppSetId),
      'questionId': serializer.toJson<String>(questionId),
      'subject': serializer.toJson<String>(subject),
      'chapter': serializer.toJson<String>(chapter),
      'topic': serializer.toJson<String>(topic),
      'topicId': serializer.toJson<String>(topicId),
      'difficulty': serializer.toJson<String>(difficulty),
      'questionText': serializer.toJson<String>(questionText),
      'options': serializer.toJson<String>(options),
      'correctAnswer': serializer.toJson<String>(correctAnswer),
      'explanation': serializer.toJson<String?>(explanation),
      'year': serializer.toJson<int?>(year),
      'source': serializer.toJson<String>(source),
    };
  }

  DppQuestion copyWith({
    int? id,
    Value<int?> dppSetId = const Value.absent(),
    String? questionId,
    String? subject,
    String? chapter,
    String? topic,
    String? topicId,
    String? difficulty,
    String? questionText,
    String? options,
    String? correctAnswer,
    Value<String?> explanation = const Value.absent(),
    Value<int?> year = const Value.absent(),
    String? source,
  }) => DppQuestion(
    id: id ?? this.id,
    dppSetId: dppSetId.present ? dppSetId.value : this.dppSetId,
    questionId: questionId ?? this.questionId,
    subject: subject ?? this.subject,
    chapter: chapter ?? this.chapter,
    topic: topic ?? this.topic,
    topicId: topicId ?? this.topicId,
    difficulty: difficulty ?? this.difficulty,
    questionText: questionText ?? this.questionText,
    options: options ?? this.options,
    correctAnswer: correctAnswer ?? this.correctAnswer,
    explanation: explanation.present ? explanation.value : this.explanation,
    year: year.present ? year.value : this.year,
    source: source ?? this.source,
  );
  DppQuestion copyWithCompanion(DppQuestionsCompanion data) {
    return DppQuestion(
      id: data.id.present ? data.id.value : this.id,
      dppSetId: data.dppSetId.present ? data.dppSetId.value : this.dppSetId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      subject: data.subject.present ? data.subject.value : this.subject,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      topic: data.topic.present ? data.topic.value : this.topic,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      questionText: data.questionText.present
          ? data.questionText.value
          : this.questionText,
      options: data.options.present ? data.options.value : this.options,
      correctAnswer: data.correctAnswer.present
          ? data.correctAnswer.value
          : this.correctAnswer,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      year: data.year.present ? data.year.value : this.year,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DppQuestion(')
          ..write('id: $id, ')
          ..write('dppSetId: $dppSetId, ')
          ..write('questionId: $questionId, ')
          ..write('subject: $subject, ')
          ..write('chapter: $chapter, ')
          ..write('topic: $topic, ')
          ..write('topicId: $topicId, ')
          ..write('difficulty: $difficulty, ')
          ..write('questionText: $questionText, ')
          ..write('options: $options, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('explanation: $explanation, ')
          ..write('year: $year, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dppSetId,
    questionId,
    subject,
    chapter,
    topic,
    topicId,
    difficulty,
    questionText,
    options,
    correctAnswer,
    explanation,
    year,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DppQuestion &&
          other.id == this.id &&
          other.dppSetId == this.dppSetId &&
          other.questionId == this.questionId &&
          other.subject == this.subject &&
          other.chapter == this.chapter &&
          other.topic == this.topic &&
          other.topicId == this.topicId &&
          other.difficulty == this.difficulty &&
          other.questionText == this.questionText &&
          other.options == this.options &&
          other.correctAnswer == this.correctAnswer &&
          other.explanation == this.explanation &&
          other.year == this.year &&
          other.source == this.source);
}

class DppQuestionsCompanion extends UpdateCompanion<DppQuestion> {
  final Value<int> id;
  final Value<int?> dppSetId;
  final Value<String> questionId;
  final Value<String> subject;
  final Value<String> chapter;
  final Value<String> topic;
  final Value<String> topicId;
  final Value<String> difficulty;
  final Value<String> questionText;
  final Value<String> options;
  final Value<String> correctAnswer;
  final Value<String?> explanation;
  final Value<int?> year;
  final Value<String> source;
  const DppQuestionsCompanion({
    this.id = const Value.absent(),
    this.dppSetId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.subject = const Value.absent(),
    this.chapter = const Value.absent(),
    this.topic = const Value.absent(),
    this.topicId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.questionText = const Value.absent(),
    this.options = const Value.absent(),
    this.correctAnswer = const Value.absent(),
    this.explanation = const Value.absent(),
    this.year = const Value.absent(),
    this.source = const Value.absent(),
  });
  DppQuestionsCompanion.insert({
    this.id = const Value.absent(),
    this.dppSetId = const Value.absent(),
    required String questionId,
    required String subject,
    required String chapter,
    required String topic,
    required String topicId,
    required String difficulty,
    required String questionText,
    required String options,
    required String correctAnswer,
    this.explanation = const Value.absent(),
    this.year = const Value.absent(),
    this.source = const Value.absent(),
  }) : questionId = Value(questionId),
       subject = Value(subject),
       chapter = Value(chapter),
       topic = Value(topic),
       topicId = Value(topicId),
       difficulty = Value(difficulty),
       questionText = Value(questionText),
       options = Value(options),
       correctAnswer = Value(correctAnswer);
  static Insertable<DppQuestion> custom({
    Expression<int>? id,
    Expression<int>? dppSetId,
    Expression<String>? questionId,
    Expression<String>? subject,
    Expression<String>? chapter,
    Expression<String>? topic,
    Expression<String>? topicId,
    Expression<String>? difficulty,
    Expression<String>? questionText,
    Expression<String>? options,
    Expression<String>? correctAnswer,
    Expression<String>? explanation,
    Expression<int>? year,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dppSetId != null) 'dpp_set_id': dppSetId,
      if (questionId != null) 'question_id': questionId,
      if (subject != null) 'subject': subject,
      if (chapter != null) 'chapter': chapter,
      if (topic != null) 'topic': topic,
      if (topicId != null) 'topic_id': topicId,
      if (difficulty != null) 'difficulty': difficulty,
      if (questionText != null) 'question_text': questionText,
      if (options != null) 'options': options,
      if (correctAnswer != null) 'correct_answer': correctAnswer,
      if (explanation != null) 'explanation': explanation,
      if (year != null) 'year': year,
      if (source != null) 'source': source,
    });
  }

  DppQuestionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? dppSetId,
    Value<String>? questionId,
    Value<String>? subject,
    Value<String>? chapter,
    Value<String>? topic,
    Value<String>? topicId,
    Value<String>? difficulty,
    Value<String>? questionText,
    Value<String>? options,
    Value<String>? correctAnswer,
    Value<String?>? explanation,
    Value<int?>? year,
    Value<String>? source,
  }) {
    return DppQuestionsCompanion(
      id: id ?? this.id,
      dppSetId: dppSetId ?? this.dppSetId,
      questionId: questionId ?? this.questionId,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      topic: topic ?? this.topic,
      topicId: topicId ?? this.topicId,
      difficulty: difficulty ?? this.difficulty,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      year: year ?? this.year,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dppSetId.present) {
      map['dpp_set_id'] = Variable<int>(dppSetId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<String>(chapter.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (questionText.present) {
      map['question_text'] = Variable<String>(questionText.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    if (correctAnswer.present) {
      map['correct_answer'] = Variable<String>(correctAnswer.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DppQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('dppSetId: $dppSetId, ')
          ..write('questionId: $questionId, ')
          ..write('subject: $subject, ')
          ..write('chapter: $chapter, ')
          ..write('topic: $topic, ')
          ..write('topicId: $topicId, ')
          ..write('difficulty: $difficulty, ')
          ..write('questionText: $questionText, ')
          ..write('options: $options, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('explanation: $explanation, ')
          ..write('year: $year, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuestionsTable questions = $QuestionsTable(this);
  late final $QuizAttemptsTable quizAttempts = $QuizAttemptsTable(this);
  late final $TopicProgressEntriesTable topicProgressEntries =
      $TopicProgressEntriesTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $ChatsTable chats = $ChatsTable(this);
  late final $DailyGoalsTable dailyGoals = $DailyGoalsTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $ErrorBookTable errorBook = $ErrorBookTable(this);
  late final $EvaluationsTable evaluations = $EvaluationsTable(this);
  late final $SyncWatermarksTable syncWatermarks = $SyncWatermarksTable(this);
  late final $SpacedRepetitionTable spacedRepetition = $SpacedRepetitionTable(
    this,
  );
  late final $FlashcardsTable flashcards = $FlashcardsTable(this);
  late final $DppSetsTable dppSets = $DppSetsTable(this);
  late final $DppQuestionsTable dppQuestions = $DppQuestionsTable(this);
  late final Index bookmarksQuestionIdUnique = Index(
    'bookmarks_question_id_unique',
    'CREATE UNIQUE INDEX bookmarks_question_id_unique ON bookmarks (question_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    questions,
    quizAttempts,
    topicProgressEntries,
    bookmarks,
    chats,
    dailyGoals,
    users,
    errorBook,
    evaluations,
    syncWatermarks,
    spacedRepetition,
    flashcards,
    dppSets,
    dppQuestions,
    bookmarksQuestionIdUnique,
  ];
}

typedef $$QuestionsTableCreateCompanionBuilder =
    QuestionsCompanion Function({
      required String id,
      required String subject,
      required String chapter,
      required String topic,
      Value<String> topicId,
      required String questionText,
      required String options,
      required String correctAnswer,
      Value<String?> explanation,
      Value<String?> ncertReference,
      Value<int?> year,
      Value<String> difficulty,
      Value<String?> tags,
      Value<String?> imageUrl,
      Value<String> type,
      Value<String?> remoteId,
      Value<DateTime?> updatedAt,
      Value<bool> isActive,
      Value<String> source,
      Value<int> rowid,
    });
typedef $$QuestionsTableUpdateCompanionBuilder =
    QuestionsCompanion Function({
      Value<String> id,
      Value<String> subject,
      Value<String> chapter,
      Value<String> topic,
      Value<String> topicId,
      Value<String> questionText,
      Value<String> options,
      Value<String> correctAnswer,
      Value<String?> explanation,
      Value<String?> ncertReference,
      Value<int?> year,
      Value<String> difficulty,
      Value<String?> tags,
      Value<String?> imageUrl,
      Value<String> type,
      Value<String?> remoteId,
      Value<DateTime?> updatedAt,
      Value<bool> isActive,
      Value<String> source,
      Value<int> rowid,
    });

class $$QuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ncertReference => $composableBuilder(
    column: $table.ncertReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ncertReference => $composableBuilder(
    column: $table.ncertReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ncertReference => $composableBuilder(
    column: $table.ncertReference,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$QuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestionsTable,
          Question,
          $$QuestionsTableFilterComposer,
          $$QuestionsTableOrderingComposer,
          $$QuestionsTableAnnotationComposer,
          $$QuestionsTableCreateCompanionBuilder,
          $$QuestionsTableUpdateCompanionBuilder,
          (Question, BaseReferences<_$AppDatabase, $QuestionsTable, Question>),
          Question,
          PrefetchHooks Function()
        > {
  $$QuestionsTableTableManager(_$AppDatabase db, $QuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> chapter = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<String> questionText = const Value.absent(),
                Value<String> options = const Value.absent(),
                Value<String> correctAnswer = const Value.absent(),
                Value<String?> explanation = const Value.absent(),
                Value<String?> ncertReference = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionsCompanion(
                id: id,
                subject: subject,
                chapter: chapter,
                topic: topic,
                topicId: topicId,
                questionText: questionText,
                options: options,
                correctAnswer: correctAnswer,
                explanation: explanation,
                ncertReference: ncertReference,
                year: year,
                difficulty: difficulty,
                tags: tags,
                imageUrl: imageUrl,
                type: type,
                remoteId: remoteId,
                updatedAt: updatedAt,
                isActive: isActive,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String subject,
                required String chapter,
                required String topic,
                Value<String> topicId = const Value.absent(),
                required String questionText,
                required String options,
                required String correctAnswer,
                Value<String?> explanation = const Value.absent(),
                Value<String?> ncertReference = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionsCompanion.insert(
                id: id,
                subject: subject,
                chapter: chapter,
                topic: topic,
                topicId: topicId,
                questionText: questionText,
                options: options,
                correctAnswer: correctAnswer,
                explanation: explanation,
                ncertReference: ncertReference,
                year: year,
                difficulty: difficulty,
                tags: tags,
                imageUrl: imageUrl,
                type: type,
                remoteId: remoteId,
                updatedAt: updatedAt,
                isActive: isActive,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestionsTable,
      Question,
      $$QuestionsTableFilterComposer,
      $$QuestionsTableOrderingComposer,
      $$QuestionsTableAnnotationComposer,
      $$QuestionsTableCreateCompanionBuilder,
      $$QuestionsTableUpdateCompanionBuilder,
      (Question, BaseReferences<_$AppDatabase, $QuestionsTable, Question>),
      Question,
      PrefetchHooks Function()
    >;
typedef $$QuizAttemptsTableCreateCompanionBuilder =
    QuizAttemptsCompanion Function({
      Value<int> id,
      required String topicId,
      required String subject,
      required int score,
      Value<int> incorrectCount,
      required int totalQuestions,
      required int timeSpentSeconds,
      required DateTime attemptedAt,
      required String selectedAnswers,
      Value<String> testType,
      Value<String?> subjectScores,
      Value<int?> rawScore,
      Value<int?> maxMarks,
      Value<String?> questionIds,
      Value<int?> seed,
      Value<DateTime?> updatedAt,
    });
typedef $$QuizAttemptsTableUpdateCompanionBuilder =
    QuizAttemptsCompanion Function({
      Value<int> id,
      Value<String> topicId,
      Value<String> subject,
      Value<int> score,
      Value<int> incorrectCount,
      Value<int> totalQuestions,
      Value<int> timeSpentSeconds,
      Value<DateTime> attemptedAt,
      Value<String> selectedAnswers,
      Value<String> testType,
      Value<String?> subjectScores,
      Value<int?> rawScore,
      Value<int?> maxMarks,
      Value<String?> questionIds,
      Value<int?> seed,
      Value<DateTime?> updatedAt,
    });

class $$QuizAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $QuizAttemptsTable> {
  $$QuizAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get incorrectCount => $composableBuilder(
    column: $table.incorrectCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSpentSeconds => $composableBuilder(
    column: $table.timeSpentSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedAnswers => $composableBuilder(
    column: $table.selectedAnswers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get testType => $composableBuilder(
    column: $table.testType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectScores => $composableBuilder(
    column: $table.subjectScores,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rawScore => $composableBuilder(
    column: $table.rawScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxMarks => $composableBuilder(
    column: $table.maxMarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionIds => $composableBuilder(
    column: $table.questionIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuizAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizAttemptsTable> {
  $$QuizAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get incorrectCount => $composableBuilder(
    column: $table.incorrectCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSpentSeconds => $composableBuilder(
    column: $table.timeSpentSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedAnswers => $composableBuilder(
    column: $table.selectedAnswers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get testType => $composableBuilder(
    column: $table.testType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectScores => $composableBuilder(
    column: $table.subjectScores,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rawScore => $composableBuilder(
    column: $table.rawScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxMarks => $composableBuilder(
    column: $table.maxMarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionIds => $composableBuilder(
    column: $table.questionIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuizAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizAttemptsTable> {
  $$QuizAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get incorrectCount => $composableBuilder(
    column: $table.incorrectCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeSpentSeconds => $composableBuilder(
    column: $table.timeSpentSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedAnswers => $composableBuilder(
    column: $table.selectedAnswers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get testType =>
      $composableBuilder(column: $table.testType, builder: (column) => column);

  GeneratedColumn<String> get subjectScores => $composableBuilder(
    column: $table.subjectScores,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rawScore =>
      $composableBuilder(column: $table.rawScore, builder: (column) => column);

  GeneratedColumn<int> get maxMarks =>
      $composableBuilder(column: $table.maxMarks, builder: (column) => column);

  GeneratedColumn<String> get questionIds => $composableBuilder(
    column: $table.questionIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QuizAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizAttemptsTable,
          QuizAttempt,
          $$QuizAttemptsTableFilterComposer,
          $$QuizAttemptsTableOrderingComposer,
          $$QuizAttemptsTableAnnotationComposer,
          $$QuizAttemptsTableCreateCompanionBuilder,
          $$QuizAttemptsTableUpdateCompanionBuilder,
          (
            QuizAttempt,
            BaseReferences<_$AppDatabase, $QuizAttemptsTable, QuizAttempt>,
          ),
          QuizAttempt,
          PrefetchHooks Function()
        > {
  $$QuizAttemptsTableTableManager(_$AppDatabase db, $QuizAttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> incorrectCount = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<int> timeSpentSeconds = const Value.absent(),
                Value<DateTime> attemptedAt = const Value.absent(),
                Value<String> selectedAnswers = const Value.absent(),
                Value<String> testType = const Value.absent(),
                Value<String?> subjectScores = const Value.absent(),
                Value<int?> rawScore = const Value.absent(),
                Value<int?> maxMarks = const Value.absent(),
                Value<String?> questionIds = const Value.absent(),
                Value<int?> seed = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => QuizAttemptsCompanion(
                id: id,
                topicId: topicId,
                subject: subject,
                score: score,
                incorrectCount: incorrectCount,
                totalQuestions: totalQuestions,
                timeSpentSeconds: timeSpentSeconds,
                attemptedAt: attemptedAt,
                selectedAnswers: selectedAnswers,
                testType: testType,
                subjectScores: subjectScores,
                rawScore: rawScore,
                maxMarks: maxMarks,
                questionIds: questionIds,
                seed: seed,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String topicId,
                required String subject,
                required int score,
                Value<int> incorrectCount = const Value.absent(),
                required int totalQuestions,
                required int timeSpentSeconds,
                required DateTime attemptedAt,
                required String selectedAnswers,
                Value<String> testType = const Value.absent(),
                Value<String?> subjectScores = const Value.absent(),
                Value<int?> rawScore = const Value.absent(),
                Value<int?> maxMarks = const Value.absent(),
                Value<String?> questionIds = const Value.absent(),
                Value<int?> seed = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => QuizAttemptsCompanion.insert(
                id: id,
                topicId: topicId,
                subject: subject,
                score: score,
                incorrectCount: incorrectCount,
                totalQuestions: totalQuestions,
                timeSpentSeconds: timeSpentSeconds,
                attemptedAt: attemptedAt,
                selectedAnswers: selectedAnswers,
                testType: testType,
                subjectScores: subjectScores,
                rawScore: rawScore,
                maxMarks: maxMarks,
                questionIds: questionIds,
                seed: seed,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuizAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizAttemptsTable,
      QuizAttempt,
      $$QuizAttemptsTableFilterComposer,
      $$QuizAttemptsTableOrderingComposer,
      $$QuizAttemptsTableAnnotationComposer,
      $$QuizAttemptsTableCreateCompanionBuilder,
      $$QuizAttemptsTableUpdateCompanionBuilder,
      (
        QuizAttempt,
        BaseReferences<_$AppDatabase, $QuizAttemptsTable, QuizAttempt>,
      ),
      QuizAttempt,
      PrefetchHooks Function()
    >;
typedef $$TopicProgressEntriesTableCreateCompanionBuilder =
    TopicProgressEntriesCompanion Function({
      required String topicId,
      Value<int> questionsAttempted,
      Value<int> questionsCorrect,
      Value<int> timeSpentSeconds,
      Value<double> averageTimeSeconds,
      required DateTime lastAttempted,
      Value<bool> isCompleted,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$TopicProgressEntriesTableUpdateCompanionBuilder =
    TopicProgressEntriesCompanion Function({
      Value<String> topicId,
      Value<int> questionsAttempted,
      Value<int> questionsCorrect,
      Value<int> timeSpentSeconds,
      Value<double> averageTimeSeconds,
      Value<DateTime> lastAttempted,
      Value<bool> isCompleted,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$TopicProgressEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TopicProgressEntriesTable> {
  $$TopicProgressEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionsAttempted => $composableBuilder(
    column: $table.questionsAttempted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionsCorrect => $composableBuilder(
    column: $table.questionsCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSpentSeconds => $composableBuilder(
    column: $table.timeSpentSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageTimeSeconds => $composableBuilder(
    column: $table.averageTimeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttempted => $composableBuilder(
    column: $table.lastAttempted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TopicProgressEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TopicProgressEntriesTable> {
  $$TopicProgressEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionsAttempted => $composableBuilder(
    column: $table.questionsAttempted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionsCorrect => $composableBuilder(
    column: $table.questionsCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSpentSeconds => $composableBuilder(
    column: $table.timeSpentSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageTimeSeconds => $composableBuilder(
    column: $table.averageTimeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttempted => $composableBuilder(
    column: $table.lastAttempted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TopicProgressEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TopicProgressEntriesTable> {
  $$TopicProgressEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<int> get questionsAttempted => $composableBuilder(
    column: $table.questionsAttempted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get questionsCorrect => $composableBuilder(
    column: $table.questionsCorrect,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeSpentSeconds => $composableBuilder(
    column: $table.timeSpentSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageTimeSeconds => $composableBuilder(
    column: $table.averageTimeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttempted => $composableBuilder(
    column: $table.lastAttempted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TopicProgressEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TopicProgressEntriesTable,
          TopicProgressEntry,
          $$TopicProgressEntriesTableFilterComposer,
          $$TopicProgressEntriesTableOrderingComposer,
          $$TopicProgressEntriesTableAnnotationComposer,
          $$TopicProgressEntriesTableCreateCompanionBuilder,
          $$TopicProgressEntriesTableUpdateCompanionBuilder,
          (
            TopicProgressEntry,
            BaseReferences<
              _$AppDatabase,
              $TopicProgressEntriesTable,
              TopicProgressEntry
            >,
          ),
          TopicProgressEntry,
          PrefetchHooks Function()
        > {
  $$TopicProgressEntriesTableTableManager(
    _$AppDatabase db,
    $TopicProgressEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicProgressEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicProgressEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TopicProgressEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> topicId = const Value.absent(),
                Value<int> questionsAttempted = const Value.absent(),
                Value<int> questionsCorrect = const Value.absent(),
                Value<int> timeSpentSeconds = const Value.absent(),
                Value<double> averageTimeSeconds = const Value.absent(),
                Value<DateTime> lastAttempted = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TopicProgressEntriesCompanion(
                topicId: topicId,
                questionsAttempted: questionsAttempted,
                questionsCorrect: questionsCorrect,
                timeSpentSeconds: timeSpentSeconds,
                averageTimeSeconds: averageTimeSeconds,
                lastAttempted: lastAttempted,
                isCompleted: isCompleted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String topicId,
                Value<int> questionsAttempted = const Value.absent(),
                Value<int> questionsCorrect = const Value.absent(),
                Value<int> timeSpentSeconds = const Value.absent(),
                Value<double> averageTimeSeconds = const Value.absent(),
                required DateTime lastAttempted,
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TopicProgressEntriesCompanion.insert(
                topicId: topicId,
                questionsAttempted: questionsAttempted,
                questionsCorrect: questionsCorrect,
                timeSpentSeconds: timeSpentSeconds,
                averageTimeSeconds: averageTimeSeconds,
                lastAttempted: lastAttempted,
                isCompleted: isCompleted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TopicProgressEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TopicProgressEntriesTable,
      TopicProgressEntry,
      $$TopicProgressEntriesTableFilterComposer,
      $$TopicProgressEntriesTableOrderingComposer,
      $$TopicProgressEntriesTableAnnotationComposer,
      $$TopicProgressEntriesTableCreateCompanionBuilder,
      $$TopicProgressEntriesTableUpdateCompanionBuilder,
      (
        TopicProgressEntry,
        BaseReferences<
          _$AppDatabase,
          $TopicProgressEntriesTable,
          TopicProgressEntry
        >,
      ),
      TopicProgressEntry,
      PrefetchHooks Function()
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      required String questionId,
      required String subject,
      required String topicId,
      required DateTime bookmarkedAt,
      Value<DateTime?> updatedAt,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      Value<String> questionId,
      Value<String> subject,
      Value<String> topicId,
      Value<DateTime> bookmarkedAt,
      Value<DateTime?> updatedAt,
    });

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get bookmarkedAt => $composableBuilder(
    column: $table.bookmarkedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get bookmarkedAt => $composableBuilder(
    column: $table.bookmarkedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<DateTime> get bookmarkedAt => $composableBuilder(
    column: $table.bookmarkedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>),
          Bookmark,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<DateTime> bookmarkedAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                questionId: questionId,
                subject: subject,
                topicId: topicId,
                bookmarkedAt: bookmarkedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String questionId,
                required String subject,
                required String topicId,
                required DateTime bookmarkedAt,
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                questionId: questionId,
                subject: subject,
                topicId: topicId,
                bookmarkedAt: bookmarkedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>),
      Bookmark,
      PrefetchHooks Function()
    >;
typedef $$ChatsTableCreateCompanionBuilder =
    ChatsCompanion Function({
      Value<int> id,
      required String message,
      required bool isUser,
      required DateTime timestamp,
      Value<String?> sessionId,
    });
typedef $$ChatsTableUpdateCompanionBuilder =
    ChatsCompanion Function({
      Value<int> id,
      Value<String> message,
      Value<bool> isUser,
      Value<DateTime> timestamp,
      Value<String?> sessionId,
    });

class $$ChatsTableFilterComposer extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUser => $composableBuilder(
    column: $table.isUser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUser => $composableBuilder(
    column: $table.isUser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<bool> get isUser =>
      $composableBuilder(column: $table.isUser, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);
}

class $$ChatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatsTable,
          Chat,
          $$ChatsTableFilterComposer,
          $$ChatsTableOrderingComposer,
          $$ChatsTableAnnotationComposer,
          $$ChatsTableCreateCompanionBuilder,
          $$ChatsTableUpdateCompanionBuilder,
          (Chat, BaseReferences<_$AppDatabase, $ChatsTable, Chat>),
          Chat,
          PrefetchHooks Function()
        > {
  $$ChatsTableTableManager(_$AppDatabase db, $ChatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<bool> isUser = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
              }) => ChatsCompanion(
                id: id,
                message: message,
                isUser: isUser,
                timestamp: timestamp,
                sessionId: sessionId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String message,
                required bool isUser,
                required DateTime timestamp,
                Value<String?> sessionId = const Value.absent(),
              }) => ChatsCompanion.insert(
                id: id,
                message: message,
                isUser: isUser,
                timestamp: timestamp,
                sessionId: sessionId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatsTable,
      Chat,
      $$ChatsTableFilterComposer,
      $$ChatsTableOrderingComposer,
      $$ChatsTableAnnotationComposer,
      $$ChatsTableCreateCompanionBuilder,
      $$ChatsTableUpdateCompanionBuilder,
      (Chat, BaseReferences<_$AppDatabase, $ChatsTable, Chat>),
      Chat,
      PrefetchHooks Function()
    >;
typedef $$DailyGoalsTableCreateCompanionBuilder =
    DailyGoalsCompanion Function({
      required DateTime date,
      Value<int> target,
      Value<int> completed,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$DailyGoalsTableUpdateCompanionBuilder =
    DailyGoalsCompanion Function({
      Value<DateTime> date,
      Value<int> target,
      Value<int> completed,
      Value<String> status,
      Value<int> rowid,
    });

class $$DailyGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyGoalsTable> {
  $$DailyGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyGoalsTable> {
  $$DailyGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyGoalsTable> {
  $$DailyGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<int> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$DailyGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyGoalsTable,
          DailyGoal,
          $$DailyGoalsTableFilterComposer,
          $$DailyGoalsTableOrderingComposer,
          $$DailyGoalsTableAnnotationComposer,
          $$DailyGoalsTableCreateCompanionBuilder,
          $$DailyGoalsTableUpdateCompanionBuilder,
          (
            DailyGoal,
            BaseReferences<_$AppDatabase, $DailyGoalsTable, DailyGoal>,
          ),
          DailyGoal,
          PrefetchHooks Function()
        > {
  $$DailyGoalsTableTableManager(_$AppDatabase db, $DailyGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> date = const Value.absent(),
                Value<int> target = const Value.absent(),
                Value<int> completed = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyGoalsCompanion(
                date: date,
                target: target,
                completed: completed,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime date,
                Value<int> target = const Value.absent(),
                Value<int> completed = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyGoalsCompanion.insert(
                date: date,
                target: target,
                completed: completed,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyGoalsTable,
      DailyGoal,
      $$DailyGoalsTableFilterComposer,
      $$DailyGoalsTableOrderingComposer,
      $$DailyGoalsTableAnnotationComposer,
      $$DailyGoalsTableCreateCompanionBuilder,
      $$DailyGoalsTableUpdateCompanionBuilder,
      (DailyGoal, BaseReferences<_$AppDatabase, $DailyGoalsTable, DailyGoal>),
      DailyGoal,
      PrefetchHooks Function()
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String?> email,
      Value<String?> phone,
      required String username,
      Value<String?> passwordHash,
      Value<String?> fullName,
      Value<DateTime> createdAt,
      Value<DateTime?> lastLogin,
      Value<bool> isActive,
      Value<bool> isEmailVerified,
      Value<bool> isPhoneVerified,
      Value<bool> isTwoFactorEnabled,
      Value<int> currentStreak,
      Value<DateTime?> lastActivityDate,
      Value<String?> batch,
      Value<int?> targetYear,
      Value<int?> dailyCommitmentMinutes,
      Value<String?> passwordResetCode,
      Value<DateTime?> passwordResetExpiresAt,
      Value<String?> twoFactorCode,
      Value<DateTime?> twoFactorExpiresAt,
      Value<String?> supabaseId,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String?> email,
      Value<String?> phone,
      Value<String> username,
      Value<String?> passwordHash,
      Value<String?> fullName,
      Value<DateTime> createdAt,
      Value<DateTime?> lastLogin,
      Value<bool> isActive,
      Value<bool> isEmailVerified,
      Value<bool> isPhoneVerified,
      Value<bool> isTwoFactorEnabled,
      Value<int> currentStreak,
      Value<DateTime?> lastActivityDate,
      Value<String?> batch,
      Value<int?> targetYear,
      Value<int?> dailyCommitmentMinutes,
      Value<String?> passwordResetCode,
      Value<DateTime?> passwordResetExpiresAt,
      Value<String?> twoFactorCode,
      Value<DateTime?> twoFactorExpiresAt,
      Value<String?> supabaseId,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastLogin => $composableBuilder(
    column: $table.lastLogin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEmailVerified => $composableBuilder(
    column: $table.isEmailVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPhoneVerified => $composableBuilder(
    column: $table.isPhoneVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTwoFactorEnabled => $composableBuilder(
    column: $table.isTwoFactorEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastActivityDate => $composableBuilder(
    column: $table.lastActivityDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batch => $composableBuilder(
    column: $table.batch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetYear => $composableBuilder(
    column: $table.targetYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyCommitmentMinutes => $composableBuilder(
    column: $table.dailyCommitmentMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordResetCode => $composableBuilder(
    column: $table.passwordResetCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get passwordResetExpiresAt => $composableBuilder(
    column: $table.passwordResetExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get twoFactorCode => $composableBuilder(
    column: $table.twoFactorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get twoFactorExpiresAt => $composableBuilder(
    column: $table.twoFactorExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastLogin => $composableBuilder(
    column: $table.lastLogin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEmailVerified => $composableBuilder(
    column: $table.isEmailVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPhoneVerified => $composableBuilder(
    column: $table.isPhoneVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTwoFactorEnabled => $composableBuilder(
    column: $table.isTwoFactorEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastActivityDate => $composableBuilder(
    column: $table.lastActivityDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batch => $composableBuilder(
    column: $table.batch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetYear => $composableBuilder(
    column: $table.targetYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyCommitmentMinutes => $composableBuilder(
    column: $table.dailyCommitmentMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordResetCode => $composableBuilder(
    column: $table.passwordResetCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get passwordResetExpiresAt => $composableBuilder(
    column: $table.passwordResetExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get twoFactorCode => $composableBuilder(
    column: $table.twoFactorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get twoFactorExpiresAt => $composableBuilder(
    column: $table.twoFactorExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLogin =>
      $composableBuilder(column: $table.lastLogin, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isEmailVerified => $composableBuilder(
    column: $table.isEmailVerified,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPhoneVerified => $composableBuilder(
    column: $table.isPhoneVerified,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTwoFactorEnabled => $composableBuilder(
    column: $table.isTwoFactorEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastActivityDate => $composableBuilder(
    column: $table.lastActivityDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get batch =>
      $composableBuilder(column: $table.batch, builder: (column) => column);

  GeneratedColumn<int> get targetYear => $composableBuilder(
    column: $table.targetYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyCommitmentMinutes => $composableBuilder(
    column: $table.dailyCommitmentMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get passwordResetCode => $composableBuilder(
    column: $table.passwordResetCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get passwordResetExpiresAt => $composableBuilder(
    column: $table.passwordResetExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get twoFactorCode => $composableBuilder(
    column: $table.twoFactorCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get twoFactorExpiresAt => $composableBuilder(
    column: $table.twoFactorExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String?> passwordHash = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastLogin = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isEmailVerified = const Value.absent(),
                Value<bool> isPhoneVerified = const Value.absent(),
                Value<bool> isTwoFactorEnabled = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<DateTime?> lastActivityDate = const Value.absent(),
                Value<String?> batch = const Value.absent(),
                Value<int?> targetYear = const Value.absent(),
                Value<int?> dailyCommitmentMinutes = const Value.absent(),
                Value<String?> passwordResetCode = const Value.absent(),
                Value<DateTime?> passwordResetExpiresAt = const Value.absent(),
                Value<String?> twoFactorCode = const Value.absent(),
                Value<DateTime?> twoFactorExpiresAt = const Value.absent(),
                Value<String?> supabaseId = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                email: email,
                phone: phone,
                username: username,
                passwordHash: passwordHash,
                fullName: fullName,
                createdAt: createdAt,
                lastLogin: lastLogin,
                isActive: isActive,
                isEmailVerified: isEmailVerified,
                isPhoneVerified: isPhoneVerified,
                isTwoFactorEnabled: isTwoFactorEnabled,
                currentStreak: currentStreak,
                lastActivityDate: lastActivityDate,
                batch: batch,
                targetYear: targetYear,
                dailyCommitmentMinutes: dailyCommitmentMinutes,
                passwordResetCode: passwordResetCode,
                passwordResetExpiresAt: passwordResetExpiresAt,
                twoFactorCode: twoFactorCode,
                twoFactorExpiresAt: twoFactorExpiresAt,
                supabaseId: supabaseId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                required String username,
                Value<String?> passwordHash = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastLogin = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isEmailVerified = const Value.absent(),
                Value<bool> isPhoneVerified = const Value.absent(),
                Value<bool> isTwoFactorEnabled = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<DateTime?> lastActivityDate = const Value.absent(),
                Value<String?> batch = const Value.absent(),
                Value<int?> targetYear = const Value.absent(),
                Value<int?> dailyCommitmentMinutes = const Value.absent(),
                Value<String?> passwordResetCode = const Value.absent(),
                Value<DateTime?> passwordResetExpiresAt = const Value.absent(),
                Value<String?> twoFactorCode = const Value.absent(),
                Value<DateTime?> twoFactorExpiresAt = const Value.absent(),
                Value<String?> supabaseId = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                email: email,
                phone: phone,
                username: username,
                passwordHash: passwordHash,
                fullName: fullName,
                createdAt: createdAt,
                lastLogin: lastLogin,
                isActive: isActive,
                isEmailVerified: isEmailVerified,
                isPhoneVerified: isPhoneVerified,
                isTwoFactorEnabled: isTwoFactorEnabled,
                currentStreak: currentStreak,
                lastActivityDate: lastActivityDate,
                batch: batch,
                targetYear: targetYear,
                dailyCommitmentMinutes: dailyCommitmentMinutes,
                passwordResetCode: passwordResetCode,
                passwordResetExpiresAt: passwordResetExpiresAt,
                twoFactorCode: twoFactorCode,
                twoFactorExpiresAt: twoFactorExpiresAt,
                supabaseId: supabaseId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$ErrorBookTableCreateCompanionBuilder =
    ErrorBookCompanion Function({
      required String questionId,
      required DateTime addedAt,
      Value<int> retryCount,
      Value<bool> isResolved,
      Value<int> rowid,
    });
typedef $$ErrorBookTableUpdateCompanionBuilder =
    ErrorBookCompanion Function({
      Value<String> questionId,
      Value<DateTime> addedAt,
      Value<int> retryCount,
      Value<bool> isResolved,
      Value<int> rowid,
    });

class $$ErrorBookTableFilterComposer
    extends Composer<_$AppDatabase, $ErrorBookTable> {
  $$ErrorBookTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isResolved => $composableBuilder(
    column: $table.isResolved,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ErrorBookTableOrderingComposer
    extends Composer<_$AppDatabase, $ErrorBookTable> {
  $$ErrorBookTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isResolved => $composableBuilder(
    column: $table.isResolved,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ErrorBookTableAnnotationComposer
    extends Composer<_$AppDatabase, $ErrorBookTable> {
  $$ErrorBookTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isResolved => $composableBuilder(
    column: $table.isResolved,
    builder: (column) => column,
  );
}

class $$ErrorBookTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ErrorBookTable,
          ErrorBookData,
          $$ErrorBookTableFilterComposer,
          $$ErrorBookTableOrderingComposer,
          $$ErrorBookTableAnnotationComposer,
          $$ErrorBookTableCreateCompanionBuilder,
          $$ErrorBookTableUpdateCompanionBuilder,
          (
            ErrorBookData,
            BaseReferences<_$AppDatabase, $ErrorBookTable, ErrorBookData>,
          ),
          ErrorBookData,
          PrefetchHooks Function()
        > {
  $$ErrorBookTableTableManager(_$AppDatabase db, $ErrorBookTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ErrorBookTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ErrorBookTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ErrorBookTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> questionId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<bool> isResolved = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ErrorBookCompanion(
                questionId: questionId,
                addedAt: addedAt,
                retryCount: retryCount,
                isResolved: isResolved,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questionId,
                required DateTime addedAt,
                Value<int> retryCount = const Value.absent(),
                Value<bool> isResolved = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ErrorBookCompanion.insert(
                questionId: questionId,
                addedAt: addedAt,
                retryCount: retryCount,
                isResolved: isResolved,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ErrorBookTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ErrorBookTable,
      ErrorBookData,
      $$ErrorBookTableFilterComposer,
      $$ErrorBookTableOrderingComposer,
      $$ErrorBookTableAnnotationComposer,
      $$ErrorBookTableCreateCompanionBuilder,
      $$ErrorBookTableUpdateCompanionBuilder,
      (
        ErrorBookData,
        BaseReferences<_$AppDatabase, $ErrorBookTable, ErrorBookData>,
      ),
      ErrorBookData,
      PrefetchHooks Function()
    >;
typedef $$EvaluationsTableCreateCompanionBuilder =
    EvaluationsCompanion Function({
      Value<int> id,
      required String questionId,
      required String studentAnswer,
      required double score,
      required double semanticSimilarity,
      required double keywordMatch,
      required bool isCorrect,
      Value<String?> feedback,
      Value<String?> missingKeywords,
      required DateTime evaluatedAt,
    });
typedef $$EvaluationsTableUpdateCompanionBuilder =
    EvaluationsCompanion Function({
      Value<int> id,
      Value<String> questionId,
      Value<String> studentAnswer,
      Value<double> score,
      Value<double> semanticSimilarity,
      Value<double> keywordMatch,
      Value<bool> isCorrect,
      Value<String?> feedback,
      Value<String?> missingKeywords,
      Value<DateTime> evaluatedAt,
    });

class $$EvaluationsTableFilterComposer
    extends Composer<_$AppDatabase, $EvaluationsTable> {
  $$EvaluationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentAnswer => $composableBuilder(
    column: $table.studentAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get semanticSimilarity => $composableBuilder(
    column: $table.semanticSimilarity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get keywordMatch => $composableBuilder(
    column: $table.keywordMatch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedback => $composableBuilder(
    column: $table.feedback,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missingKeywords => $composableBuilder(
    column: $table.missingKeywords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get evaluatedAt => $composableBuilder(
    column: $table.evaluatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EvaluationsTableOrderingComposer
    extends Composer<_$AppDatabase, $EvaluationsTable> {
  $$EvaluationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentAnswer => $composableBuilder(
    column: $table.studentAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get semanticSimilarity => $composableBuilder(
    column: $table.semanticSimilarity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get keywordMatch => $composableBuilder(
    column: $table.keywordMatch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedback => $composableBuilder(
    column: $table.feedback,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missingKeywords => $composableBuilder(
    column: $table.missingKeywords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get evaluatedAt => $composableBuilder(
    column: $table.evaluatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EvaluationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EvaluationsTable> {
  $$EvaluationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get studentAnswer => $composableBuilder(
    column: $table.studentAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<double> get semanticSimilarity => $composableBuilder(
    column: $table.semanticSimilarity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get keywordMatch => $composableBuilder(
    column: $table.keywordMatch,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<String> get feedback =>
      $composableBuilder(column: $table.feedback, builder: (column) => column);

  GeneratedColumn<String> get missingKeywords => $composableBuilder(
    column: $table.missingKeywords,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get evaluatedAt => $composableBuilder(
    column: $table.evaluatedAt,
    builder: (column) => column,
  );
}

class $$EvaluationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EvaluationsTable,
          Evaluation,
          $$EvaluationsTableFilterComposer,
          $$EvaluationsTableOrderingComposer,
          $$EvaluationsTableAnnotationComposer,
          $$EvaluationsTableCreateCompanionBuilder,
          $$EvaluationsTableUpdateCompanionBuilder,
          (
            Evaluation,
            BaseReferences<_$AppDatabase, $EvaluationsTable, Evaluation>,
          ),
          Evaluation,
          PrefetchHooks Function()
        > {
  $$EvaluationsTableTableManager(_$AppDatabase db, $EvaluationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EvaluationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EvaluationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EvaluationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String> studentAnswer = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<double> semanticSimilarity = const Value.absent(),
                Value<double> keywordMatch = const Value.absent(),
                Value<bool> isCorrect = const Value.absent(),
                Value<String?> feedback = const Value.absent(),
                Value<String?> missingKeywords = const Value.absent(),
                Value<DateTime> evaluatedAt = const Value.absent(),
              }) => EvaluationsCompanion(
                id: id,
                questionId: questionId,
                studentAnswer: studentAnswer,
                score: score,
                semanticSimilarity: semanticSimilarity,
                keywordMatch: keywordMatch,
                isCorrect: isCorrect,
                feedback: feedback,
                missingKeywords: missingKeywords,
                evaluatedAt: evaluatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String questionId,
                required String studentAnswer,
                required double score,
                required double semanticSimilarity,
                required double keywordMatch,
                required bool isCorrect,
                Value<String?> feedback = const Value.absent(),
                Value<String?> missingKeywords = const Value.absent(),
                required DateTime evaluatedAt,
              }) => EvaluationsCompanion.insert(
                id: id,
                questionId: questionId,
                studentAnswer: studentAnswer,
                score: score,
                semanticSimilarity: semanticSimilarity,
                keywordMatch: keywordMatch,
                isCorrect: isCorrect,
                feedback: feedback,
                missingKeywords: missingKeywords,
                evaluatedAt: evaluatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EvaluationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EvaluationsTable,
      Evaluation,
      $$EvaluationsTableFilterComposer,
      $$EvaluationsTableOrderingComposer,
      $$EvaluationsTableAnnotationComposer,
      $$EvaluationsTableCreateCompanionBuilder,
      $$EvaluationsTableUpdateCompanionBuilder,
      (
        Evaluation,
        BaseReferences<_$AppDatabase, $EvaluationsTable, Evaluation>,
      ),
      Evaluation,
      PrefetchHooks Function()
    >;
typedef $$SyncWatermarksTableCreateCompanionBuilder =
    SyncWatermarksCompanion Function({
      required String remoteTable,
      required DateTime lastSyncedAt,
      Value<int> rowid,
    });
typedef $$SyncWatermarksTableUpdateCompanionBuilder =
    SyncWatermarksCompanion Function({
      Value<String> remoteTable,
      Value<DateTime> lastSyncedAt,
      Value<int> rowid,
    });

class $$SyncWatermarksTableFilterComposer
    extends Composer<_$AppDatabase, $SyncWatermarksTable> {
  $$SyncWatermarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get remoteTable => $composableBuilder(
    column: $table.remoteTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncWatermarksTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncWatermarksTable> {
  $$SyncWatermarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get remoteTable => $composableBuilder(
    column: $table.remoteTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncWatermarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncWatermarksTable> {
  $$SyncWatermarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get remoteTable => $composableBuilder(
    column: $table.remoteTable,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncWatermarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncWatermarksTable,
          SyncWatermark,
          $$SyncWatermarksTableFilterComposer,
          $$SyncWatermarksTableOrderingComposer,
          $$SyncWatermarksTableAnnotationComposer,
          $$SyncWatermarksTableCreateCompanionBuilder,
          $$SyncWatermarksTableUpdateCompanionBuilder,
          (
            SyncWatermark,
            BaseReferences<_$AppDatabase, $SyncWatermarksTable, SyncWatermark>,
          ),
          SyncWatermark,
          PrefetchHooks Function()
        > {
  $$SyncWatermarksTableTableManager(
    _$AppDatabase db,
    $SyncWatermarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncWatermarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncWatermarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncWatermarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> remoteTable = const Value.absent(),
                Value<DateTime> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncWatermarksCompanion(
                remoteTable: remoteTable,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String remoteTable,
                required DateTime lastSyncedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncWatermarksCompanion.insert(
                remoteTable: remoteTable,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncWatermarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncWatermarksTable,
      SyncWatermark,
      $$SyncWatermarksTableFilterComposer,
      $$SyncWatermarksTableOrderingComposer,
      $$SyncWatermarksTableAnnotationComposer,
      $$SyncWatermarksTableCreateCompanionBuilder,
      $$SyncWatermarksTableUpdateCompanionBuilder,
      (
        SyncWatermark,
        BaseReferences<_$AppDatabase, $SyncWatermarksTable, SyncWatermark>,
      ),
      SyncWatermark,
      PrefetchHooks Function()
    >;
typedef $$SpacedRepetitionTableCreateCompanionBuilder =
    SpacedRepetitionCompanion Function({
      required String questionId,
      Value<int> box,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<int> lapses,
      required DateTime dueAt,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$SpacedRepetitionTableUpdateCompanionBuilder =
    SpacedRepetitionCompanion Function({
      Value<String> questionId,
      Value<int> box,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<int> lapses,
      Value<DateTime> dueAt,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$SpacedRepetitionTableFilterComposer
    extends Composer<_$AppDatabase, $SpacedRepetitionTable> {
  $$SpacedRepetitionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SpacedRepetitionTableOrderingComposer
    extends Composer<_$AppDatabase, $SpacedRepetitionTable> {
  $$SpacedRepetitionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SpacedRepetitionTableAnnotationComposer
    extends Composer<_$AppDatabase, $SpacedRepetitionTable> {
  $$SpacedRepetitionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get box =>
      $composableBuilder(column: $table.box, builder: (column) => column);

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SpacedRepetitionTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SpacedRepetitionTable,
          SpacedRepetitionData,
          $$SpacedRepetitionTableFilterComposer,
          $$SpacedRepetitionTableOrderingComposer,
          $$SpacedRepetitionTableAnnotationComposer,
          $$SpacedRepetitionTableCreateCompanionBuilder,
          $$SpacedRepetitionTableUpdateCompanionBuilder,
          (
            SpacedRepetitionData,
            BaseReferences<
              _$AppDatabase,
              $SpacedRepetitionTable,
              SpacedRepetitionData
            >,
          ),
          SpacedRepetitionData,
          PrefetchHooks Function()
        > {
  $$SpacedRepetitionTableTableManager(
    _$AppDatabase db,
    $SpacedRepetitionTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpacedRepetitionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpacedRepetitionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpacedRepetitionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> questionId = const Value.absent(),
                Value<int> box = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SpacedRepetitionCompanion(
                questionId: questionId,
                box: box,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                lapses: lapses,
                dueAt: dueAt,
                lastReviewedAt: lastReviewedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questionId,
                Value<int> box = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                required DateTime dueAt,
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SpacedRepetitionCompanion.insert(
                questionId: questionId,
                box: box,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                lapses: lapses,
                dueAt: dueAt,
                lastReviewedAt: lastReviewedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SpacedRepetitionTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SpacedRepetitionTable,
      SpacedRepetitionData,
      $$SpacedRepetitionTableFilterComposer,
      $$SpacedRepetitionTableOrderingComposer,
      $$SpacedRepetitionTableAnnotationComposer,
      $$SpacedRepetitionTableCreateCompanionBuilder,
      $$SpacedRepetitionTableUpdateCompanionBuilder,
      (
        SpacedRepetitionData,
        BaseReferences<
          _$AppDatabase,
          $SpacedRepetitionTable,
          SpacedRepetitionData
        >,
      ),
      SpacedRepetitionData,
      PrefetchHooks Function()
    >;
typedef $$FlashcardsTableCreateCompanionBuilder =
    FlashcardsCompanion Function({
      required String id,
      required String front,
      required String back,
      required String subject,
      Value<String> topicId,
      Value<String?> imageUrl,
      Value<String> chapterId,
      Value<String> ncertReference,
      Value<int> sourcePage,
      Value<String> difficulty,
      Value<bool> isGenerated,
      Value<int> box,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<int> lapses,
      required DateTime dueAt,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$FlashcardsTableUpdateCompanionBuilder =
    FlashcardsCompanion Function({
      Value<String> id,
      Value<String> front,
      Value<String> back,
      Value<String> subject,
      Value<String> topicId,
      Value<String?> imageUrl,
      Value<String> chapterId,
      Value<String> ncertReference,
      Value<int> sourcePage,
      Value<String> difficulty,
      Value<bool> isGenerated,
      Value<int> box,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<int> lapses,
      Value<DateTime> dueAt,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$FlashcardsTableFilterComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapterId => $composableBuilder(
    column: $table.chapterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ncertReference => $composableBuilder(
    column: $table.ncertReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourcePage => $composableBuilder(
    column: $table.sourcePage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGenerated => $composableBuilder(
    column: $table.isGenerated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FlashcardsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapterId => $composableBuilder(
    column: $table.chapterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ncertReference => $composableBuilder(
    column: $table.ncertReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourcePage => $composableBuilder(
    column: $table.sourcePage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGenerated => $composableBuilder(
    column: $table.isGenerated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FlashcardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get front =>
      $composableBuilder(column: $table.front, builder: (column) => column);

  GeneratedColumn<String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<String> get ncertReference => $composableBuilder(
    column: $table.ncertReference,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourcePage => $composableBuilder(
    column: $table.sourcePage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isGenerated => $composableBuilder(
    column: $table.isGenerated,
    builder: (column) => column,
  );

  GeneratedColumn<int> get box =>
      $composableBuilder(column: $table.box, builder: (column) => column);

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FlashcardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlashcardsTable,
          Flashcard,
          $$FlashcardsTableFilterComposer,
          $$FlashcardsTableOrderingComposer,
          $$FlashcardsTableAnnotationComposer,
          $$FlashcardsTableCreateCompanionBuilder,
          $$FlashcardsTableUpdateCompanionBuilder,
          (
            Flashcard,
            BaseReferences<_$AppDatabase, $FlashcardsTable, Flashcard>,
          ),
          Flashcard,
          PrefetchHooks Function()
        > {
  $$FlashcardsTableTableManager(_$AppDatabase db, $FlashcardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlashcardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlashcardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlashcardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> front = const Value.absent(),
                Value<String> back = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> chapterId = const Value.absent(),
                Value<String> ncertReference = const Value.absent(),
                Value<int> sourcePage = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<bool> isGenerated = const Value.absent(),
                Value<int> box = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlashcardsCompanion(
                id: id,
                front: front,
                back: back,
                subject: subject,
                topicId: topicId,
                imageUrl: imageUrl,
                chapterId: chapterId,
                ncertReference: ncertReference,
                sourcePage: sourcePage,
                difficulty: difficulty,
                isGenerated: isGenerated,
                box: box,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                lapses: lapses,
                dueAt: dueAt,
                lastReviewedAt: lastReviewedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String front,
                required String back,
                required String subject,
                Value<String> topicId = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> chapterId = const Value.absent(),
                Value<String> ncertReference = const Value.absent(),
                Value<int> sourcePage = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<bool> isGenerated = const Value.absent(),
                Value<int> box = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                required DateTime dueAt,
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlashcardsCompanion.insert(
                id: id,
                front: front,
                back: back,
                subject: subject,
                topicId: topicId,
                imageUrl: imageUrl,
                chapterId: chapterId,
                ncertReference: ncertReference,
                sourcePage: sourcePage,
                difficulty: difficulty,
                isGenerated: isGenerated,
                box: box,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                lapses: lapses,
                dueAt: dueAt,
                lastReviewedAt: lastReviewedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FlashcardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlashcardsTable,
      Flashcard,
      $$FlashcardsTableFilterComposer,
      $$FlashcardsTableOrderingComposer,
      $$FlashcardsTableAnnotationComposer,
      $$FlashcardsTableCreateCompanionBuilder,
      $$FlashcardsTableUpdateCompanionBuilder,
      (Flashcard, BaseReferences<_$AppDatabase, $FlashcardsTable, Flashcard>),
      Flashcard,
      PrefetchHooks Function()
    >;
typedef $$DppSetsTableCreateCompanionBuilder =
    DppSetsCompanion Function({
      Value<int> id,
      required String date,
      required String subject,
      Value<String?> chapterId,
      Value<String?> topicId,
      required int totalQuestions,
      Value<int?> durationMinutes,
      Value<int> correctCount,
      Value<int> incorrectCount,
      Value<int> unattemptedCount,
      Value<int> timeSpentSeconds,
      Value<bool> isCompleted,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
    });
typedef $$DppSetsTableUpdateCompanionBuilder =
    DppSetsCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String> subject,
      Value<String?> chapterId,
      Value<String?> topicId,
      Value<int> totalQuestions,
      Value<int?> durationMinutes,
      Value<int> correctCount,
      Value<int> incorrectCount,
      Value<int> unattemptedCount,
      Value<int> timeSpentSeconds,
      Value<bool> isCompleted,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
    });

class $$DppSetsTableFilterComposer
    extends Composer<_$AppDatabase, $DppSetsTable> {
  $$DppSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapterId => $composableBuilder(
    column: $table.chapterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get incorrectCount => $composableBuilder(
    column: $table.incorrectCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unattemptedCount => $composableBuilder(
    column: $table.unattemptedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSpentSeconds => $composableBuilder(
    column: $table.timeSpentSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DppSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $DppSetsTable> {
  $$DppSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapterId => $composableBuilder(
    column: $table.chapterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get incorrectCount => $composableBuilder(
    column: $table.incorrectCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unattemptedCount => $composableBuilder(
    column: $table.unattemptedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSpentSeconds => $composableBuilder(
    column: $table.timeSpentSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DppSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DppSetsTable> {
  $$DppSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get incorrectCount => $composableBuilder(
    column: $table.incorrectCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unattemptedCount => $composableBuilder(
    column: $table.unattemptedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeSpentSeconds => $composableBuilder(
    column: $table.timeSpentSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DppSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DppSetsTable,
          DppSet,
          $$DppSetsTableFilterComposer,
          $$DppSetsTableOrderingComposer,
          $$DppSetsTableAnnotationComposer,
          $$DppSetsTableCreateCompanionBuilder,
          $$DppSetsTableUpdateCompanionBuilder,
          (DppSet, BaseReferences<_$AppDatabase, $DppSetsTable, DppSet>),
          DppSet,
          PrefetchHooks Function()
        > {
  $$DppSetsTableTableManager(_$AppDatabase db, $DppSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DppSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DppSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DppSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String?> chapterId = const Value.absent(),
                Value<String?> topicId = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> incorrectCount = const Value.absent(),
                Value<int> unattemptedCount = const Value.absent(),
                Value<int> timeSpentSeconds = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => DppSetsCompanion(
                id: id,
                date: date,
                subject: subject,
                chapterId: chapterId,
                topicId: topicId,
                totalQuestions: totalQuestions,
                durationMinutes: durationMinutes,
                correctCount: correctCount,
                incorrectCount: incorrectCount,
                unattemptedCount: unattemptedCount,
                timeSpentSeconds: timeSpentSeconds,
                isCompleted: isCompleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required String subject,
                Value<String?> chapterId = const Value.absent(),
                Value<String?> topicId = const Value.absent(),
                required int totalQuestions,
                Value<int?> durationMinutes = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> incorrectCount = const Value.absent(),
                Value<int> unattemptedCount = const Value.absent(),
                Value<int> timeSpentSeconds = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => DppSetsCompanion.insert(
                id: id,
                date: date,
                subject: subject,
                chapterId: chapterId,
                topicId: topicId,
                totalQuestions: totalQuestions,
                durationMinutes: durationMinutes,
                correctCount: correctCount,
                incorrectCount: incorrectCount,
                unattemptedCount: unattemptedCount,
                timeSpentSeconds: timeSpentSeconds,
                isCompleted: isCompleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DppSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DppSetsTable,
      DppSet,
      $$DppSetsTableFilterComposer,
      $$DppSetsTableOrderingComposer,
      $$DppSetsTableAnnotationComposer,
      $$DppSetsTableCreateCompanionBuilder,
      $$DppSetsTableUpdateCompanionBuilder,
      (DppSet, BaseReferences<_$AppDatabase, $DppSetsTable, DppSet>),
      DppSet,
      PrefetchHooks Function()
    >;
typedef $$DppQuestionsTableCreateCompanionBuilder =
    DppQuestionsCompanion Function({
      Value<int> id,
      Value<int?> dppSetId,
      required String questionId,
      required String subject,
      required String chapter,
      required String topic,
      required String topicId,
      required String difficulty,
      required String questionText,
      required String options,
      required String correctAnswer,
      Value<String?> explanation,
      Value<int?> year,
      Value<String> source,
    });
typedef $$DppQuestionsTableUpdateCompanionBuilder =
    DppQuestionsCompanion Function({
      Value<int> id,
      Value<int?> dppSetId,
      Value<String> questionId,
      Value<String> subject,
      Value<String> chapter,
      Value<String> topic,
      Value<String> topicId,
      Value<String> difficulty,
      Value<String> questionText,
      Value<String> options,
      Value<String> correctAnswer,
      Value<String?> explanation,
      Value<int?> year,
      Value<String> source,
    });

class $$DppQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $DppQuestionsTable> {
  $$DppQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dppSetId => $composableBuilder(
    column: $table.dppSetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DppQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DppQuestionsTable> {
  $$DppQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dppSetId => $composableBuilder(
    column: $table.dppSetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DppQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DppQuestionsTable> {
  $$DppQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dppSetId =>
      $composableBuilder(column: $table.dppSetId, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$DppQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DppQuestionsTable,
          DppQuestion,
          $$DppQuestionsTableFilterComposer,
          $$DppQuestionsTableOrderingComposer,
          $$DppQuestionsTableAnnotationComposer,
          $$DppQuestionsTableCreateCompanionBuilder,
          $$DppQuestionsTableUpdateCompanionBuilder,
          (
            DppQuestion,
            BaseReferences<_$AppDatabase, $DppQuestionsTable, DppQuestion>,
          ),
          DppQuestion,
          PrefetchHooks Function()
        > {
  $$DppQuestionsTableTableManager(_$AppDatabase db, $DppQuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DppQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DppQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DppQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> dppSetId = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> chapter = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> questionText = const Value.absent(),
                Value<String> options = const Value.absent(),
                Value<String> correctAnswer = const Value.absent(),
                Value<String?> explanation = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => DppQuestionsCompanion(
                id: id,
                dppSetId: dppSetId,
                questionId: questionId,
                subject: subject,
                chapter: chapter,
                topic: topic,
                topicId: topicId,
                difficulty: difficulty,
                questionText: questionText,
                options: options,
                correctAnswer: correctAnswer,
                explanation: explanation,
                year: year,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> dppSetId = const Value.absent(),
                required String questionId,
                required String subject,
                required String chapter,
                required String topic,
                required String topicId,
                required String difficulty,
                required String questionText,
                required String options,
                required String correctAnswer,
                Value<String?> explanation = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => DppQuestionsCompanion.insert(
                id: id,
                dppSetId: dppSetId,
                questionId: questionId,
                subject: subject,
                chapter: chapter,
                topic: topic,
                topicId: topicId,
                difficulty: difficulty,
                questionText: questionText,
                options: options,
                correctAnswer: correctAnswer,
                explanation: explanation,
                year: year,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DppQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DppQuestionsTable,
      DppQuestion,
      $$DppQuestionsTableFilterComposer,
      $$DppQuestionsTableOrderingComposer,
      $$DppQuestionsTableAnnotationComposer,
      $$DppQuestionsTableCreateCompanionBuilder,
      $$DppQuestionsTableUpdateCompanionBuilder,
      (
        DppQuestion,
        BaseReferences<_$AppDatabase, $DppQuestionsTable, DppQuestion>,
      ),
      DppQuestion,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db, _db.questions);
  $$QuizAttemptsTableTableManager get quizAttempts =>
      $$QuizAttemptsTableTableManager(_db, _db.quizAttempts);
  $$TopicProgressEntriesTableTableManager get topicProgressEntries =>
      $$TopicProgressEntriesTableTableManager(_db, _db.topicProgressEntries);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$ChatsTableTableManager get chats =>
      $$ChatsTableTableManager(_db, _db.chats);
  $$DailyGoalsTableTableManager get dailyGoals =>
      $$DailyGoalsTableTableManager(_db, _db.dailyGoals);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$ErrorBookTableTableManager get errorBook =>
      $$ErrorBookTableTableManager(_db, _db.errorBook);
  $$EvaluationsTableTableManager get evaluations =>
      $$EvaluationsTableTableManager(_db, _db.evaluations);
  $$SyncWatermarksTableTableManager get syncWatermarks =>
      $$SyncWatermarksTableTableManager(_db, _db.syncWatermarks);
  $$SpacedRepetitionTableTableManager get spacedRepetition =>
      $$SpacedRepetitionTableTableManager(_db, _db.spacedRepetition);
  $$FlashcardsTableTableManager get flashcards =>
      $$FlashcardsTableTableManager(_db, _db.flashcards);
  $$DppSetsTableTableManager get dppSets =>
      $$DppSetsTableTableManager(_db, _db.dppSets);
  $$DppQuestionsTableTableManager get dppQuestions =>
      $$DppQuestionsTableTableManager(_db, _db.dppQuestions);
}
