import 'package:flutter/material.dart';
import 'selection_overlay.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const EdgeInsets _contentPadding = EdgeInsets.fromLTRB(12, 20, 12, 20);
  static const EdgeInsets _overlayPadding = EdgeInsets.fromLTRB(16, 19, 12, 20);

  final TextEditingController _controller1 = TextEditingController(
    text:
        'The quick brown fox jumps over the lazy dog. This is some random text to demonstrate the TextFormField widget. The quick brown fox jumps over the lazy dog. This is some random text to demonstrate the TextFormField widget. The quick brown fox jumps over the lazy dog. This is some random text to demonstrate the TextFormField widget. ',
  );
  final TextEditingController _controller2 = TextEditingController();
  final FocusNode _focusNode1 = FocusNode();
  final ScrollController _scrollController1 = ScrollController();
  TextSelection? _savedSelection;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _focusNode1.addListener(_onFocusChange);
    _scrollController1.addListener(_onScrollChange);
  }

  void _onScrollChange() {
    setState(() {
      _scrollOffset = _scrollController1.offset;
    });
  }

  void _onFocusChange() {
    setState(() {
      if (_focusNode1.hasFocus) {
        if (_savedSelection != null) {
          _controller1.selection = _savedSelection!;
        }
      } else {
        _savedSelection = _controller1.selection;
      }
    });
  }

  @override
  void dispose() {
    _focusNode1.removeListener(_onFocusChange);
    _scrollController1.removeListener(_onScrollChange);
    _focusNode1.dispose();
    _scrollController1.dispose();
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(
              children: [
                TextFormField(
                  controller: _controller1,
                  focusNode: _focusNode1,
                  scrollController: _scrollController1,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'First Field',
                    contentPadding: _contentPadding,
                  ),
                  maxLines: 3,
                ),
                if (!_focusNode1.hasFocus && _savedSelection != null)
                  Positioned.fill(
                    child: ClipRect(
                      child: IgnorePointer(
                        child: Padding(
                          padding: _overlayPadding,
                          child: TextSelectionHighlight(
                            text: _controller1.text,
                            selection: _savedSelection!,
                            style:
                                Theme.of(context).textTheme.bodyLarge ??
                                const TextStyle(fontSize: 16.0),
                            maxLines: 3,
                            scrollOffset: _scrollOffset,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _controller2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Second Field',
                contentPadding: _contentPadding,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
