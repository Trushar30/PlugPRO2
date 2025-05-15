import 'package:flutter/material.dart';
import 'dart:math';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _addBotMessage(
      'Hello! I\'m your PlugPRO AI assistant. How can I help you with your home service needs today?',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    _messageController.clear();
    
    if (text.trim().isEmpty) {
      return;
    }
    
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _isTyping = true;
    });
    
    // Simulate bot thinking
    Future.delayed(const Duration(seconds: 1), () {
      _generateBotResponse(text);
    });
  }

  void _generateBotResponse(String userMessage) {
    final lowercaseMessage = userMessage.toLowerCase();
    String response;
    
    if (lowercaseMessage.contains('plumbing') || 
        lowercaseMessage.contains('leak') || 
        lowercaseMessage.contains('pipe')) {
      response = 'For plumbing issues like leaks or pipe problems, here are some steps:\n\n'
          '1. Turn off the water supply to stop any leaking\n'
          '2. Check if it\'s a simple issue like a loose connection\n'
          '3. For complex issues, I recommend booking a professional plumber through our app\n\n'
          'Would you like me to help you find a plumber?';
    } else if (lowercaseMessage.contains('electrical') || 
               lowercaseMessage.contains('power') || 
               lowercaseMessage.contains('light')) {
      response = 'For electrical issues, safety is the priority:\n\n'
          '1. Don\'t touch exposed wires or water near electrical issues\n'
          '2. Check if it\'s a tripped breaker first\n'
          '3. For any complex issues, please book a professional electrician\n\n'
          'Would you like me to help you find an electrician?';
    } else if (lowercaseMessage.contains('cleaning') || 
               lowercaseMessage.contains('clean')) {
      response = 'For home cleaning services, we offer:\n\n'
          '1. Regular cleaning\n'
          '2. Deep cleaning\n'
          '3. Specialized cleaning for specific areas\n\n'
          'Would you like to book a cleaning service?';
    } else if (lowercaseMessage.contains('book') || 
               lowercaseMessage.contains('service')) {
      response = 'To book a service, you can:\n\n'
          '1. Go to the Services tab\n'
          '2. Select the category you need\n'
          '3. Choose a worker based on ratings and reviews\n'
          '4. Fill in the details about your problem\n'
          '5. Select payment method and confirm booking\n\n'
          'Is there a specific service you\'re looking to book?';
    } else if (lowercaseMessage.contains('subscription') || 
               lowercaseMessage.contains('plan')) {
      response = 'Our subscription plans offer regular services at discounted rates:\n\n'
          '1. Basic Plan: One service per month for 3 months\n'
          '2. Standard Plan: Two services per month for 6 months\n'
          '3. Premium Plan: Three services per month for 12 months\n\n'
          'You can view and purchase these plans in the Subscription tab.';
    } else if (lowercaseMessage.contains('payment') || 
               lowercaseMessage.contains('pay')) {
      response = 'We offer two payment methods:\n\n'
          '1. Cash on Delivery: Pay directly to the worker after service\n'
          '2. Online Payment: Pay through the app\n\n'
          'Note that the initial payment is just the visiting charge. Additional charges for parts or extra work will be added after service completion.';
    } else if (lowercaseMessage.contains('cancel') || 
               lowercaseMessage.contains('reschedule')) {
      response = 'To cancel or reschedule a booking:\n\n'
          '1. Go to the History tab\n'
          '2. Find your active booking\n'
          '3. Select "View Details"\n'
          '4. Choose "Cancel Booking" if the worker hasn\'t accepted yet\n\n'
          'If the worker has already accepted, please contact them directly through the app.';
    } else if (lowercaseMessage.contains('hello') || 
               lowercaseMessage.contains('hi') || 
               lowercaseMessage.contains('hey')) {
      response = 'Hello! How can I assist you with your home service needs today?';
    } else if (lowercaseMessage.contains('thank')) {
      response = 'You\'re welcome! Is there anything else I can help you with?';
    } else {
      // Generic responses for unknown queries
      final genericResponses = [
        'I\'m not sure I understand. Could you please provide more details about your home service needs?',
        'For specific service assistance, please let me know what type of home service you\'re looking for.',
        'I can help with plumbing, electrical, cleaning, and many other home services. What do you need assistance with?',
        'Would you like me to help you book a service or just provide information?',
        'I\'m here to help with your home service needs. Could you clarify what you\'re looking for?',
      ];
      
      final random = Random();
      response = genericResponses[random.nextInt(genericResponses.length)];
    }
    
    _addBotMessage(response);
  }

  void _addBotMessage(String message) {
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: message,
        isUser: false,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _messages[index],
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('AI is typing...'),
                ],
              ),
            ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _messageController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Send a message',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _handleSubmitted(_messageController.text),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(
                Icons.smart_toy,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                'U',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
