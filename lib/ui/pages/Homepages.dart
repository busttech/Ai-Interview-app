import 'package:flutter/material.dart';
import 'package:neurotrainer/ui/pages/interview_app.dart';
import 'hrround.dart';
import 'profilepage.dart';

class InterviewHomePage extends StatefulWidget {
  const InterviewHomePage({super.key});

  @override
  State<InterviewHomePage> createState() => _InterviewHomePageState();
}

class _InterviewHomePageState extends State<InterviewHomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeInAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assests/logo.webp'),
        ),
        title: const Text('AI Interview App'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assests/profile.jpg'),
            ),
          ),
        ],
        backgroundColor: Colors.black,
        elevation: 4,
      ),
      body: _selectedIndex == 0 ? _buildHomeBody() : ProfilePage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeBody() {
    return Container(
      color: Colors.deepPurple,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Hero(
                    tag: 'interviewTitle',
                    child: Text(
                      "🧠 Choose Interview Type",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),

                  InterviewOptionCard(
                    icon: Icons.person_outline,
                    title: "HR/Behavioral Round",
                    description:
                        "Practice soft skills and behavioral questions",
                    color: Colors.blue,
                    delay: 300,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => Interviewr()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  InterviewOptionCard(
                    icon: Icons.computer,
                    title: "Technical Round",
                    description:
                        "Practice coding, system design, or technical Q&A",
                    color: Colors.teal,
                    delay: 600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => InterviewScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  InterviewOptionCard(
                    icon: Icons.work_outline,
                    title: "Case Study Round",
                    description: "Practice business and consulting  interviews",
                    color: Colors.orange,
                    delay: 900,
                    onTap: () {
                      _showComingSoon(context, "Case Study Interview");
                    },
                  ),
                  const SizedBox(height: 20),

                  InterviewOptionCard(
                    icon: Icons.lightbulb_outline,
                    title: "Aptitude Round",
                    description:
                        "Practice logical reasoning and aptitude questions",
                    color: Colors.indigo,
                    delay: 1200,
                    onTap: () {
                      _showComingSoon(context, "Aptitude Round");
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("$featureName"),
            content: const Text("🚧 This feature is coming soon. Stay tuned!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }
}

class InterviewOptionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const InterviewOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  State<InterviewOptionCard> createState() => _InterviewOptionCardState();
}

class _InterviewOptionCardState extends State<InterviewOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: widget.color.withOpacity(0.2),
          child: Card(
            elevation: 6,
            shadowColor: widget.color.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: widget.color.withOpacity(0.15),
                    child: Icon(widget.icon, color: widget.color, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
