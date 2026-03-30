import 'dart:io';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/project.dart';

class ProjectsScreen extends StatefulWidget {
  @override
  _ProjectsScreenState createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late Future<List<Project>> _projectsList;

  @override
  void initState() {
    super.initState();
    _refreshProjects();
  }

  void _refreshProjects() {
    setState(() {
      _projectsList = DatabaseHelper.instance.readAllProjects();
    });
  }

  // Exports the project to the public Downloads folder so it survives uninstalls
  Future<void> _exportToDownloads(Project project) async {
    try {
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      String safeTitle = project.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file = File('${dir.path}/${safeTitle}_Translation.txt');
      
      String content = "PROJECT: ${project.title}\n";
      content += "DATE: ${DateTime.parse(project.createdAt).toLocal()}\n";
      content += "========================================\n\n";
      content += "${project.targetLanguage.toUpperCase()} TRANSLATION:\n";
      content += "${project.translatedText}\n\n";
      content += "========================================\n\n";
      content += "ORIGINAL TRANSCRIPT:\n";
      content += "${project.englishTranscript}\n";

      await file.writeAsString(content);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to Downloads folder!'), backgroundColor: Colors.green)
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Projects', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _refreshProjects),
        ],
      ),
      body: FutureBuilder<List<Project>>(
        future: _projectsList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading projects: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No saved projects yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final projects = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final date = DateTime.parse(project.createdAt);
              
              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Icon(Icons.subtitles, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(project.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${project.targetLanguage} • ${date.day}/${date.month}/${date.year}'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${project.targetLanguage}:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                              TextButton.icon(
                                onPressed: () => _exportToDownloads(project),
                                icon: Icon(Icons.download),
                                label: Text('Export to Phone'),
                              )
                            ],
                          ),
                          SizedBox(height: 4),
                          SelectableText(project.translatedText),
                          Divider(height: 24),
                          Text('Original:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          SizedBox(height: 4),
                          SelectableText(project.englishTranscript),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
