import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path/path.dart' as path;
import '../widget/speakingavatar.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen>
    with SingleTickerProviderStateMixin {
  String? resumeText; 
  final TextEditingController jobDescController = TextEditingController();
  final TextEditingController answerController = TextEditingController();
  bool showAnswerTextField = false;
  String? question;
  bool interviewStarted = false;
  bool interviewstartedbychat = false;
  bool isLoading = false;
  int interviewDurationMinutes = 5;
  int secondsLeft = 0;
  Timer? timer;
  List<Map<String, String>> interviewHistory = [];
  bool subtittile = false;

  static const String apiKey = "";
  late GenerativeModel model;

  late FlutterTts flutterTts;
  bool _isSpeaking = false;

  late stt.SpeechToText speech;
  bool _isListening = false;
  String _recordedAnswer = "";

  // Job role dropdown options
  final List<String> jobRoles = [
    'Flutter Developer',
    'Data Scientist',
    'Backend Developer',
  ];
  String selectedJobRole = 'Flutter Developer';

  @override
  void initState() {
    super.initState();
    model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    flutterTts = FlutterTts();
    flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });
    flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
    flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
    });

    speech = stt.SpeechToText();
  }

  Future<void> pickResumeFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String ext = path.extension(file.path).toLowerCase();
      String text = "";

      if (ext == '.txt') {
        text = await file.readAsString();
      } else if (ext == '.pdf') {
        text =
            "PDF parsing not implemented yet, please provide TXT resume for now.";
      } else {
        text =
            "DOC/DOCX parsing not implemented, please provide TXT resume for now.";
      }

      setState(() {
        resumeText = text;
      });
    }
  }

  Future<void> generateSummaryAndScore() async {
    setState(() {
      isLoading = true;
    });
    print(interviewHistory);
    String history = interviewHistory
        .map((qa) {
          return "Questions: ${qa['question']}\nAnsers: ${qa['answer']}";
        })
        .join("\n\n");

    String prompt = """
You are a seasoned HR professional and behavioral interviewer. Below is a transcript of a mock **HR/Behavioral interview** for the "$selectedJobRole" role.

Your task is to **evaluate the candidate’s overall performance** based solely on the transcript, resume, and job description.

**Instructions**:
- If the candidate has given **fewer than two answers**, do **not** provide a performance review.
  - Instead, respond with:  
    **"Less data available. It seems the candidate left the interview early."**
  - Assign a score of **0 out of 100**.

- If the candidate has provided **two or more answers**, evaluate their performance based on:
  - **Depth and relevance of responses**
  - **Emotional intelligence, communication skills, and self-awareness**
  - Resume alignment and job fit
  - The job description

Provide:
- A **final score out of 100**
- A **friendly, empathetic summary** highlighting their strengths and areas for improvement

Resume:
$resumeText

Job Description:
${jobDescController.text.trim()}

Transcript:
$history

Respond in this exact format:
Score: <number>/100  
Summary: <short, warm, constructive feedback>
""";

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      String feedback = response.text?.trim() ?? "Could not generate summary.";

      // Show feedback in a dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Interview Feedback'),
              content: SingleChildScrollView(child: Text(feedback)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
      );

      setState(() {
        question = "Interview ended. See feedback above.";
      });
    } catch (e) {
      setState(() {
        question = "Error generating feedback: $e";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void startTimer() {
    secondsLeft = interviewDurationMinutes * 60;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft <= 0) {
        stopInterview();
      } else {
        setState(() {
          secondsLeft--;
        });
      }
    });
  }

  void stopInterview() async {
    timer?.cancel();
    flutterTts.stop();
    speech.stop();
    bool interviewEndedNaturally = secondsLeft <= 0;
    setState(() {
      interviewStarted = false;
      question = "Interview ended. Thanks for participating!";
      _isSpeaking = false;
      _isListening = false;
    });
    if (interviewEndedNaturally) {
      await generateSummaryAndScore();
    }
  }

  Future<void> speakQuestion(String text) async {
    if (text.isEmpty) return;
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.speak(text);
  }

  Future<void> askQuestion({
    String? resume,
    String? jobDesc,
    String? answer,
  }) async {
    setState(() {
      isLoading = true;
    });

    String prompt;

    if (resume != null && jobDesc != null && answer == null) {
      prompt = """
    You are a highly intelligent, empathetic, and professional AI simulating a human technical interviewer for the role of "$selectedJobRole".

    Your goal is to conduct a realistic, friendly, and constructive technical interview. Act as a supportive human who wants the candidate to succeed, making the experience feel natural and conversational.

    🟢 **Interview Flow**:
    - Begin with a **warm and human greeting**, e.g.,  
      _"Hi! Great to meet you. Let’s dive into a few technical questions based on your background."_
    - Then ask the **first technical question**, tailored to the candidate’s resume and job description.

    📌 **Rules**:
    - Ask **only one question at a time**.
    - Each question should be **short (1–2 lines max)**.
    - Keep questions **clear, direct, and role-relevant**.
    - The candidate responds via **speech-to-text** — please **ignore spelling or grammar errors**.
    - Stay **friendly, natural, and encouraging** — never mention AI or that this is a simulation.

    📄 Context for Personalization:

    Resume:
    $resume

    Job Description:
    $jobDesc

    Start by greeting the candidate and asking the first relevant question.
    """;
    } else if (answer != null) {
      if (question != null) {
        interviewHistory.add({'question': question!, 'answer': answer});
      }

      final normalizedAnswer = answer.toLowerCase();

      final bool isRepeatRequest =
          normalizedAnswer.contains("i don't understand") ||
          normalizedAnswer.contains("repeat") ||
          normalizedAnswer.contains("say again") ||
          normalizedAnswer.contains("can you repeat") ||
          normalizedAnswer.contains("i don't know") ||
          normalizedAnswer.contains("not sure");

      final bool isNoAnswer = answer.trim().isEmpty;

      final bool isShortAnswer = answer.trim().split(' ').length < 4;

      if (isRepeatRequest) {
        prompt = """
    The candidate responded: "$answer"

    This sounds like a request for clarification or indicates uncertainty.

    Please rephrase or repeat the **previous question** in a simpler way, while keeping your tone warm, patient, and reassuring.
    """;
      } else if (isNoAnswer) {
        prompt = """
    The candidate hasn’t answered yet.

    Please gently prompt them again with:
    _"Take your time — when you're ready, here’s the question again:"_

    Then repeat or ask the next short, relevant question.
    """;
      } else if (isShortAnswer) {
        prompt = """
    The candidate gave a brief answer: "$answer"

    Please encourage them to elaborate a bit more.

    For example, you can say:
    _"Thanks for sharing! Could you walk me through that in a bit more detail?"_

    Stay supportive and friendly.
    """;
      } else {
        prompt = """
    The candidate responded: "$answer"

    You are continuing the technical interview for the "$selectedJobRole" role.

    🎯 Please do the following:

    1. **Evaluate** the candidate’s answer based on the resume and job description.
    2. **Ignore spelling/grammar errors** (responses are speech-to-text).
    3. Give **kind, human feedback**:
      - 👍 Great: _"That’s a strong response. Thank you for explaining that so clearly!"_
      - 🤝 Okay: _"Nice effort — there’s some room for improvement, but you’re on the right track."_
      - ❗ Weak: _"Thanks for your answer. That missed the mark a bit, but no worries — let’s keep going."_

    4. If the answer is unclear or off-topic, gently guide the candidate back on track.

    Then ask the **next short, relevant technical question** (max 1–2 lines). Keep the tone supportive and constructive.

    Candidate Resume:
    $resume

    Job Description:
    $jobDesc
    """;
      }
    } else {
      prompt = """
    You are a kind, realistic, and professional AI interviewer conducting a technical interview for the "$selectedJobRole" role.

    Start with a warm greeting and then ask a **short, relevant technical question** (1–2 lines max).

    Always be patient and encouraging. Ignore minor language issues from speech-to-text input.
    """;
    }

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      String q = response.text!.trim();
      setState(() {
        question = q;
      });
      await speakQuestion(q);
    } catch (e) {
      setState(() {
        question = "Error getting question: $e";
        _isSpeaking = false;
      });
    }

    setState(() {
      isLoading = false;
      _recordedAnswer = "";
      _isListening = false;
      answerController.clear();
    });
  }

  void onStartPressed() {
    if (resumeText == null || resumeText!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your resume file')),
      );
      return;
    }
    if (jobDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the job description')),
      );
      return;
    }
    setState(() {
      interviewStarted = true;
      question = null;
    });
    askQuestion(resume: resumeText, jobDesc: jobDescController.text.trim());
    startTimer();
  }

  void onNextPressed() {
    if (_recordedAnswer.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record your answer before submitting'),
        ),
      );
      return;
    }
    askQuestion(answer: _recordedAnswer.trim());
  }

  Future<void> startListening() async {
    bool available = await speech.initialize(
      onStatus: (val) {
        if (val == 'done') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (val) {
        setState(() {
          _isListening = false;
        });
      },
    );
    if (available) {
      setState(() {
        _isListening = true;
      });
      speech.listen(
        onResult: (val) {
          setState(() {
            _recordedAnswer = val.recognizedWords;
            answerController.text = _recordedAnswer;
          });
        },
      );
    }
  }

  void stopListening() {
    speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    jobDescController.dispose();
    answerController.dispose();
    flutterTts.stop();
    speech.stop();
    super.dispose();
  }

  String formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget buildStartForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧠 Title
            Center(
              child: Text(
                'Technical Round Setup',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: pickResumeFile,
              icon: const Icon(Icons.upload_file_rounded, size: 20),
              label: const Text(
                'Upload Resume (TXT)',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),

        
            Text(
              'Job Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: jobDescController,
              maxLines: 6,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                hintText: 'Paste the job description here...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepPurpleAccent),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Job Role',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedJobRole,
              dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              iconEnabledColor: isDark ? Colors.white : Colors.black,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items:
                  jobRoles
                      .map(
                        (role) =>
                            DropdownMenuItem(value: role, child: Text(role)),
                      )
                      .toList(),
              onChanged: (val) => setState(() => selectedJobRole = val!),
            ),
            const SizedBox(height: 24),

            Text(
              'Interview Duration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: interviewDurationMinutes,
              dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              iconEnabledColor: isDark ? Colors.white : Colors.black,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 Minutes')),
                DropdownMenuItem(value: 10, child: Text('10 Minutes')),
                DropdownMenuItem(value: 15, child: Text('15 Minutes')),
              ],
              onChanged:
                  (val) => setState(() => interviewDurationMinutes = val!),
            ),
            const SizedBox(height: 30),


            Center(
              child: SizedBox(
                width: 220,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onStartPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child:
                      isLoading
                          ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                            strokeWidth: 2.5,
                          )
                          : const Text('Start Interview'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInterviewUI() {
    return Column(
      children: [

        const SizedBox(height: 200),
        SpeakingAvatar(isSpeaking: _isSpeaking),
        const SizedBox(height: 24),

        
        if (question != null && subtittile)
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.black,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                question!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        const SizedBox(height: 20),

        if (showAnswerTextField)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: answerController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Your Answer (or use mic)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (val) => _recordedAnswer = val,
            ),
          ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
              onPressed: _isListening ? stopListening : startListening,
              iconSize: 36,
              color: _isListening ? Colors.redAccent : Colors.blueAccent,
            ),
            const SizedBox(width: 24),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onNextPressed,
              icon: const Icon(Icons.send),
              label: const Text('Submit & Next'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),

        const Spacer(),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Time Left: ${formatTime(secondsLeft)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: stopInterview,
                icon: const Icon(Icons.stop),
                label: const Text('End'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        title: const Text('AI Interview App'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: interviewStarted ? buildInterviewUI() : buildStartForm(),
      ),
    );
  }
}
