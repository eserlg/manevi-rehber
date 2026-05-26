import 'dart:html' as html;

Future<bool> writeClipboardText(String text) async {
  final body = html.document.body;
  if (body == null) return false;

  html.TextAreaElement? textArea;
  try {
    textArea = html.TextAreaElement()
      ..value = text
      ..readOnly = true
      ..style.position = 'fixed'
      ..style.left = '0'
      ..style.top = '0'
      ..style.opacity = '0'
      ..style.width = '1px'
      ..style.height = '1px';

    body.append(textArea);
    textArea.focus();
    textArea.select();
    return html.document.execCommand('copy');
  } catch (_) {
    return false;
  } finally {
    textArea?.remove();
  }
}
