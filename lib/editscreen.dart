import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'secondscreen.dart';

class EditScreen extends StatefulWidget {
  final File imageFile;
  final Function(String, String) onSave; // Updated to pass title and content
  const EditScreen({Key? key, required this.imageFile, required this.onSave}) : super(key: key);

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late TextEditingController _textController;
  String _recognizedText = '';
  String? _title; // Store title here

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _performOCR(widget.imageFile); // Start OCR when the screen is loaded
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  bool _isLoading = true;


  Future<void> _performOCR(File image) async {
    setState(() {
      _isLoading = true; // Start loading
    });

    final inputImage = InputImage.fromFile(image);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    setState(() {
      _recognizedText = recognizedText.text;
      _textController.text = _recognizedText;
      _isLoading = false; // Stop loading when done
    });
  }

  void _autoSetTitleIfNeeded() {
    if (_title == null || _title!.isEmpty) {
      final words = _textController.text.trim().split(' ');
      final title = words.take(2).join(' ');
      setState(() {
        _title = title.isEmpty ? 'Untitled' : title;
      });
    }
  }

  Future<void> _createPDF() async {
    _autoSetTitleIfNeeded(); // Auto-set title if not provided

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(child: pw.Text(_textController.text));
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$_title.pdf'; // Save with title as filename
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    // Save PDF path to history with the title
    widget.onSave(_title!, 'PDF: $path');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_title PDF saved and opening...')),
    );

    // Open the created PDF
    await OpenFile.open(path);
  }

  /// Saves the edited text and returns to the HomeScreen
  void _saveText() {
    _autoSetTitleIfNeeded(); // Auto-set title if not provided

    if (_textController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter some text!')),
      );
      return;
    }

    // Save the edited text with the title
    widget.onSave(_title!, _textController.text);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SecondScreen(
              content: _textController.text,
              title: _title!, // Pass title to SecondScreen
            ),
      ),
    );
  }

  // Show dialog for title input
  Future<void> _showTitleDialog() async {
    String title = '';
    TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Title'),
          content: TextField(
            controller: titleController,
            decoration:  InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your title here',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                title = titleController.text
                    .trim()
                    .isEmpty
                    ? 'Untitled' // Default title if empty
                    : titleController.text.trim();
                setState(() {
                  _title = title; // Set the title for later use
                });
                Navigator.pop(context); // Close dialog
              },
              child:  Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding:  EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.deepPurple.shade200,
        title: Text(
            'Edit Text', style: TextStyle(color: Colors.white)),
        iconTheme:  IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [

              if (_isLoading)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // Image preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    widget.imageFile,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 16),

                // Text Field in Card
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding:  EdgeInsets.all(12.0),
                    child: TextField(
                      controller: _textController,
                      maxLines: 13,
                      keyboardType: TextInputType.multiline,
                      style:  TextStyle(fontSize: 16),
                      decoration:  InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Edit OCR Text',
                      ),
                    ),
                  ),
                ),

                 SizedBox(height: 20),

                // Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _createPDF(),
                        icon:  Icon(Icons.picture_as_pdf),
                        label:  Text('Save As PDF'),
                        style: ElevatedButton.styleFrom(
                          padding:  EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.white, width: 2),
                          ),
                          backgroundColor: Colors.deepPurple.shade200,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                     SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _saveText(),
                        icon:  Icon(Icons.save),
                        label:  Text('Save As Text'),
                        style: ElevatedButton.styleFrom(
                          padding:  EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.white, width: 2),
                          ),
                          backgroundColor: Colors.deepPurple.shade200,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                 SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}