import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/service/apiService.dart';
import '/theam/ThemeProvider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // For Clipboard

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  // add API Key
  final ApiService _apiService =
      ApiService(apiKey: 'API_KEY',);
  final ScrollController _scrollController = ScrollController();
  bool _isBotTyping = false;
  bool _isLoadingChatHistory = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  // Load chat history from SharedPreferences
  void _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getStringList('chatHistory');
    if (savedMessages != null) {
      setState(() {
        _messages.addAll(savedMessages
            .map((message) => Map<String, String>.from(json.decode(message)))
            .toList());
      });
    }
    setState(() {
      _isLoadingChatHistory = false;
    });
  }

  // Save chat history to SharedPreferences
  void _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesToSave =
        _messages.map((message) => json.encode(message)).toList();
    prefs.setStringList('chatHistory', messagesToSave);
  }

  // Function to send a message
  void _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add({
          'text': message,
          'sender': 'user',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      _controller.clear();

      // Scroll to the bottom
      _scrollToBottom();

      setState(() {
        _isBotTyping = true;
      });

      try {
        final response = await _apiService.generateContent(message);
        setState(() {
          _isBotTyping = false;
        });

        if (response != null) {
          setState(() {
            _messages.add({
              'text': response,
              'sender': 'bot',
              'timestamp': DateTime.now().toIso8601String(),
            });
          });
        } else {
          setState(() {
            _messages.add({
              'text': 'Failed to get a response.',
              'sender': 'bot',
              'timestamp': DateTime.now().toIso8601String(),
            });
          });
        }
      } catch (e) {
        setState(() {
          _isBotTyping = false;
          _messages.add({
            'text': 'Error: Unable to connect to the server.',
            'sender': 'bot',
            'timestamp': DateTime.now().toIso8601String(),
          });
        });
      }

      _scrollToBottom();
      _saveChatHistory(); // Save chat history after each message
    }
  }


  // Scroll to the bottom of the chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // Clean chat history
  void _cleanChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('chatHistory');
    setState(() {
      _messages.clear();
    });
  }

  // Copy message to clipboard
  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }


  @override
    // Update message if valid edited text is provided
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = themeProvider.getTheme();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat with Bot',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              'Bot is online',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 10,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading:
                  Icon(Icons.account_circle, color: theme.colorScheme.primary),
              title: const Text('Profile'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Profile'),
                    content: Text(
                      'Create your account to unlock personalized features and a seamless experience.',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.notifications, color: theme.colorScheme.primary),
              title: const Text('Notifications'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Notifications'),
                    content: Text(
                      'Manage your notification preferences to stay informed the way you prefer. Choose how and when you receive updates.',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.security, color: theme.colorScheme.primary),
              title: const Text('Privacy'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Privacy'),
                    content: Text(
                      'Your privacy is our priority. Learn more about how we safeguard your data and protect your personal information.',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.help, color: theme.colorScheme.primary),
              title: const Text('Help & Support'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Help & Support'),
                    content: Text(
                      'Need assistance? Our support team is here to help. Please choose an option below or contact us for further assistance.',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: theme.colorScheme.primary),
              title: const Text('Clear Chat History'),
              onTap: () {
                _cleanChatHistory();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _isLoadingChatHistory
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length + (_isBotTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isBotTyping) {
                          return _buildTypingIndicator(isDarkMode);
                        }
                        final message = _messages[index];
                        final isUser = message['sender'] == 'user';
                        return GestureDetector(
                          onLongPress: () {
                            _showMessageOptions(
                                context, index, message['text']!);
                          },
                          child: _buildMessageBubble(
                              message, isUser, isDarkMode, theme),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.white54
                                    : Colors.black54,
                              ),
                            ),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Show message options (copy and edit)
  void _showMessageOptions(BuildContext context, int index, String text) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy'),
            onTap: () {
              _copyMessage(text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Build typing indicator
  Widget _buildTypingIndicator(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            child: Icon(
              Icons.android,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Typing...',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build message bubble
  Widget _buildMessageBubble(Map<String, String> message, bool isUser,
      bool isDarkMode, ThemeData theme) {
    final timestamp = DateTime.parse(message['timestamp']!);
    final formattedTime = '${timestamp.hour}:${timestamp.minute}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              child: Icon(
                Icons.auto_awesome_rounded,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          const SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUser
                    ? [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ]
                    : [
                        isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        isDarkMode ? Colors.grey[800]! : Colors.grey[400]!,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message['text']!,
                  style: TextStyle(
                    color: isUser
                        ? Colors.white
                        : (isDarkMode ? Colors.white : Colors.black),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: TextStyle(
                    color: isUser
                        ? Colors.white70
                        : (isDarkMode ? Colors.white70 : Colors.black54),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
