import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_extract/homescreen.dart';
import 'package:share_plus/share_plus.dart';

class SecondScreen extends StatelessWidget {
  final String content;
  final String title;

  const SecondScreen({Key? key, required this.content, required this.title}) : super(key: key);

  void copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Content copied to clipboard!')),
    );
  }

  void shareContent() {
    Share.share(content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(

        actions: [
          IconButton(
            onPressed: () => copyToClipboard(context),
            icon:  Icon(Icons.copy),
            color: Colors.white,


          ),
          IconButton(
            color: Colors.white,
            onPressed: shareContent,
            icon:  Icon(Icons.share),
          ),
        ],
        title: Text(
          title,
          style:  TextStyle(
            color: Colors.white,
            fontSize: 16, // Small text size
            fontWeight: FontWeight.w600, // Semi-bold
          ),
        ),
        backgroundColor: Colors.deepPurple.shade200,
        elevation: 4,
      ),
      body: Padding(
        padding:  EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Attractive Gradient Header Card
              SizedBox(height: 15,),

              // "Saved Content" label
              Row(
                children:  [
                  Icon(Icons.description, color: Colors.black54),
                  SizedBox(width: 8),
                  Text(
                    'Saved Content',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
               Divider(height: 20, thickness: 2),

              // Content Box
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset:  Offset(0, 5),
                    ),
                  ],
                ),
                child: SelectableText(
                  content,
                  style:  TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ),

               SizedBox(height: 20),

              // Copy & Share buttons


              SizedBox(height: 30),

              // Back button

            ],
          ),
        ),
      ),
    );
  }
}
