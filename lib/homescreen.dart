import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- Added
import 'editscreen.dart';
import 'secondscreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _imageFile;
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory(); // Load history when app starts
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? historyList = prefs.getStringList('history');

    if (historyList != null) {
      setState(() {
        _history = historyList.map((item) {
          return Map<String, String>.from(json.decode(item));
        }).toList();
      });
    }
  }

  Future<void> _saveHistoryToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList =
    _history.map((item) => json.encode(item)).toList();
    await prefs.setStringList('history', historyList);
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;

    setState(() {
      _imageFile = File(pickedImage.path);
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditScreen(imageFile: _imageFile!, onSave: _saveToHistory),
      ),
    );
  }

  void _saveToHistory(String title, String content) {
    setState(() {
      if (content.startsWith('PDF: ')) {
        title = '$title.pdf';
      }
      _history.add({'title': title, 'content': content});
    });
    _saveHistoryToPrefs(); // Save updated history
  }

  void _deleteHistoryItem(int index) {
    setState(() {
      _history.removeAt(index);
    });
    _saveHistoryToPrefs(); // Save updated history
  }

  void _viewContent(String content, String title) async {
    if (content.startsWith('PDF: ')) {
      String pdfPath = content.replaceFirst('PDF: ', '');
      await OpenFile.open(pdfPath);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecondScreen(content: content, title: title),
        ),
      );
    }
  }

  String _getSubtitle(Map<String, String> item) {
    final isPdf = item['content']!.startsWith('PDF: ');
    if (isPdf) {
      String pdfPath = item['content']!.replaceFirst('PDF: ', '');
      final file = File(pdfPath);

      if (file.existsSync()) {
        int bytes = file.lengthSync();
        double kb = bytes / 1024;
        double mb = kb / 1024;
        String size = mb >= 1
            ? '${mb.toStringAsFixed(2)} MB'
            : '${kb.toStringAsFixed(0)} KB';

        return 'PDF File • $size';
      } else {
        return 'PDF File';
      }
    } else {
      return 'Text File';
    }
  }

  Widget _buildHistoryCard(Map<String, String> item, int index) {
    final isPdf = item['content']!.startsWith('PDF: ');

    return GestureDetector(
      onTap: () => _viewContent(item['content']!, item['title']!),
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 10,
              offset:  Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isPdf
                      ? [Colors.redAccent, Colors.deepOrange]
                      : [Colors.teal, Colors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding:  EdgeInsets.all(12),
              child: Icon(
                isPdf ? Icons.picture_as_pdf : Icons.text_snippet,
                color: Colors.white,
                size: 20,
              ),
            ),
             SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']!,
                    style:  TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                   SizedBox(height: 4),
                  Text(
                    _getSubtitle(item),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon:  Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteHistoryItem(index),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade200,
        elevation: 0,
        title: Text('📄 Image To Text Extract', style: TextStyle(color: Colors.white)),
        iconTheme:  IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding:  EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Text(
              'Your Files',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),
            SizedBox(height: 10),
            _history.isEmpty
                ? Container(
              margin:  EdgeInsets.only(top: 40),
              child: Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/vacancy.png',
                      height: 60,
                      width: 60,
                      opacity:  AlwaysStoppedAnimation(0.5),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No Files available.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics:  NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                return _buildHistoryCard(_history[index], index);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickImage,
        label: Text(
          'Pick Image',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:  BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
        icon: Icon(Icons.add_a_photo, color: Colors.white),
        backgroundColor: Colors.deepPurple.shade200,
      ),
    );
  }
}
