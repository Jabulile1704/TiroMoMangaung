import 'package:flutter/material.dart';

class InterviewPrepScreen extends StatelessWidget {
  const InterviewPrepScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8C42);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Preparation'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryOrange, secondaryOrange],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryOrange.withOpacity(0.1),
                  secondaryOrange.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 60,
                  color: primaryOrange,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ace Your Next Interview!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Everything you need to prepare and succeed',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Before the Interview
          _buildSection(
            title: '📋 Before the Interview',
            icon: Icons.checklist,
            items: [
              _buildTip(
                'Research the Company',
                'Visit their website, read recent news, understand their products/services and company culture.',
              ),
              _buildTip(
                'Review the Job Description',
                'Understand the requirements and prepare examples of how your experience matches.',
              ),
              _buildTip(
                'Prepare Your Documents',
                'Bring extra copies of your CV, ID, certificates, and a notebook.',
              ),
              _buildTip(
                'Plan Your Route',
                'Know exactly where you\'re going. Arrive 10-15 minutes early.',
              ),
              _buildTip(
                'Dress Professionally',
                'Choose appropriate business attire. When in doubt, err on the side of formal.',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // During the Interview
          _buildSection(
            title: '💼 During the Interview',
            icon: Icons.people,
            items: [
              _buildDoDont(
                'DO: Make eye contact and smile',
                'DON\'T: Look at your phone or watch',
              ),
              _buildDoDont(
                'DO: Listen carefully to questions',
                'DON\'T: Interrupt the interviewer',
              ),
              _buildDoDont(
                'DO: Give specific examples (STAR method)',
                'DON\'T: Give vague or generic answers',
              ),
              _buildDoDont(
                'DO: Ask thoughtful questions',
                'DON\'T: Ask about salary in first interview',
              ),
              _buildDoDont(
                'DO: Be honest about your experience',
                'DON\'T: Exaggerate or lie about skills',
              ),
              _buildDoDont(
                'DO: Show enthusiasm for the role',
                'DON\'T: Speak negatively about past employers',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // STAR Method
          _buildStarMethod(),

          const SizedBox(height: 24),

          // Common Questions
          _buildSection(
            title: '❓ Common Interview Questions',
            icon: Icons.question_answer,
            items: [
              _buildQuestion(
                'Tell me about yourself',
                'Give a 2-minute summary of your professional journey, highlighting relevant experience.',
              ),
              _buildQuestion(
                'Why do you want this job?',
                'Show you\'ve researched the company and explain how the role aligns with your career goals.',
              ),
              _buildQuestion(
                'What are your strengths?',
                'Choose 2-3 strengths relevant to the job and provide examples.',
              ),
              _buildQuestion(
                'What is your weakness?',
                'Be honest but show you\'re working on improvement. Avoid "I\'m a perfectionist".',
              ),
              _buildQuestion(
                'Where do you see yourself in 5 years?',
                'Show ambition and commitment, but be realistic about the role.',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Questions to Ask
          _buildSection(
            title: '🤔 Questions YOU Should Ask',
            icon: Icons.psychology,
            items: [
              _buildBulletPoint(
                  'What does a typical day look like in this role?'),
              _buildBulletPoint(
                  'What are the biggest challenges facing the team?'),
              _buildBulletPoint('How do you measure success in this position?'),
              _buildBulletPoint(
                  'What opportunities are there for professional development?'),
              _buildBulletPoint('What is the company culture like?'),
              _buildBulletPoint(
                  'What are the next steps in the hiring process?'),
            ],
          ),

          const SizedBox(height: 24),

          // After the Interview
          _buildSection(
            title: '✉️ After the Interview',
            icon: Icons.email,
            items: [
              _buildTip(
                'Send a Thank You Email',
                'Within 24 hours, thank them for their time and reiterate your interest.',
              ),
              _buildTip(
                'Follow Up Appropriately',
                'If you haven\'t heard back in the timeframe they mentioned, send a polite follow-up.',
              ),
              _buildTip(
                'Reflect on Your Performance',
                'Note what went well and what you can improve for next time.',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Red Flags
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      '🚩 Red Flags to Watch For',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRedFlag('Being asked to pay any money upfront'),
                _buildRedFlag('Vague job descriptions or responsibilities'),
                _buildRedFlag('Pressure to accept immediately'),
                _buildRedFlag('No formal interview process'),
                _buildRedFlag('Requests for excessive personal information'),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryOrange, secondaryOrange],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _buildTip(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDoDont(String doText, String dontText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(doText, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.cancel, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(dontText, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarMethod() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryOrange.withOpacity(0.1),
            secondaryOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⭐ The STAR Method',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use this framework to answer behavioral questions:',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildStarPoint('S', 'Situation', 'Set the context for your story'),
          _buildStarPoint('T', 'Task', 'Explain the challenge you faced'),
          _buildStarPoint('A', 'Action', 'Describe what YOU did specifically'),
          _buildStarPoint('R', 'Result', 'Share the positive outcome'),
        ],
      ),
    );
  }

  Widget _buildStarPoint(String letter, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryOrange, secondaryOrange],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(String question, String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tip,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontSize: 20, color: primaryOrange)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildRedFlag(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
