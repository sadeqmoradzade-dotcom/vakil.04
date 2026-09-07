import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VakilApp());
}

class VakilApp extends StatelessWidget {
  const VakilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'وکیل - جستجوی قوانین',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  static const String _baseUrl = 'https://rc.majlis.ir';
  static const String _searchApi = '$_baseUrl/fa/search/searchAjax';

  bool _loading = false;
  String _message = 'عبارت موردنظر را وارد کنید';
  List<Map<String, dynamic>> _results = [];

  Future<void> _search() async {
    final query = _controller.text.trim();

    if (query.length < 3) {
      setState(() {
        _results = [];
        _message = 'حداقل ۳ حرف وارد کنید';
      });
      return;
    }

    setState(() {
      _loading = true;
      _results = [];
      _message = '';
    });

    try {
      final uri = Uri.parse(_searchApi).replace(
        queryParameters: <String, String>{
          'q': query,
          'law': 'law',
        },
      );

      final response = await http.get(
        uri,
        headers: const <String, String>{
          'Accept': 'application/json, text/javascript, */*; q=0.01',
          'User-Agent': 'Mozilla/5.0',
          'Referer': 'https://rc.majlis.ir/fa/',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('خطای سرور: ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map) {
        throw Exception('پاسخ سامانه معتبر نیست');
      }

      final rawResults = decoded['result'];
      final parsedResults = <Map<String, dynamic>>[];

      if (rawResults is List) {
        for (final item in rawResults) {
          if (item is Map) {
            parsedResults.add(Map<String, dynamic>.from(item));
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _results = parsedResults;
        _message = parsedResults.isEmpty ? 'نتیجه‌ای پیدا نشد' : '';
      });
    } catch (e) {
      if (!mounted) return;

      final error = e.toString();

      setState(() {
        if (error.contains('Failed host lookup') ||
            error.contains('SocketException')) {
          _message =
              'خطا در اتصال به سامانه\n\n'
              'دامنه rc.majlis.ir از اینترنت فعلی شما پیدا نشد.\n'
              'اینترنت و DNS را بررسی کنید و دوباره تلاش کنید.';
        } else if (error.contains('TimeoutException')) {
          _message =
              'زمان اتصال به سامانه تمام شد.\nلطفاً دوباره تلاش کنید.';
        } else {
          _message = 'خطا در جستجو:\n\n$error';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openLink(String link) async {
    if (link.trim().isEmpty) return;

    var url = link.trim();

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = url.startsWith('/') ? '$_baseUrl$url' : '$_baseUrl/$url';
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      _showSnackBar('لینک نتیجه معتبر نیست');
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showSnackBar('امکان باز کردن لینک وجود ندارد');
    }
  }

  void _showSnackBar(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('وکیل - جستجوی قوانین'),
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loading ? null : _search(),
                decoration: InputDecoration(
                  hintText: 'مثلاً مهندس ناظر',
                  border: const OutlineInputBorder(),
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _loading ? null : _search,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final item = _results[index];

                            final title =
                                item['title']?.toString() ?? '';
                            final date =
                                item['date_fa']?.toString() ?? '';
                            final type =
                                item['tbl_value']?.toString() ?? '';
                            final link =
                                item['link']?.toString() ?? '';

                            final details = <String>[
                              if (date.isNotEmpty) date,
                              if (type.isNotEmpty) type,
                            ];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              child: ListTile(
                                title: Text(
                                  title.isEmpty ? 'بدون عنوان' : title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: details.isEmpty
                                    ? null
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(details.join(' | ')),
                                      ),
                                trailing:
                                    const Icon(Icons.open_in_new),
                                onTap: () => _openLink(link),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
