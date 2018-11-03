import 'package:marker/ast.dart';
import 'package:marker/marker.dart';

isBlock(node) =>
    node is Header ||
    node is Paragraph ||
    node is BlockQuote ||
    node is OrderedList ||
    node is UnorderedList;




class Header extends Node {
  final int level;

  Header(this.level);

  render(Context context) => '#' * level + ' ${super.render(context)}\n';
}

class Paragraph extends Node {
  render(Context context) => super.render(context) + '\n\n';
}

class LineBreak extends Node {
  render(Context context) => '  \n';
}

class BlockQuote extends Node {
  render(Context context) =>
      super
          .render(context)
          .trim()
          .split('\n')
          .map((line) => ('> ' + line).trim())
          .join('\n') +
      '\n\n';
}

class UnorderedList extends Node {
  render(Context context) =>
      children.map((node) => '- ${node.render(context)}').join() + '\n';
}

class OrderedList extends Node {
  render(Context context) {
    int i = 1;
    return children.map((node) => '${i++}. ${node.render(context)}').join() +
        '\n';
  }
}

class ListItem extends Node {
  render(Context context) {
    if (children.isNotEmpty && isBlock(children.first)) {
      return children
              .map((node) {
                if (node is BlockQuote) {
                  return '    ' +
                      node.render(context).split('\n').join('\n    ');
                }
                if (node is Pre) {
                  // A code block in a list gets 3 spaces
                  // despite the standard requiring 4.
                  // @see https://daringfireball.net/projects/markdown/syntax#list
                  // So we have to compensate here.
                  return '   ' + node.render(context).split('\n').join('\n   ');
                }
                return '    ' + node.render(context).trim();
              })
              .join('\n\n')
              .trim() +
          '\n\n';
    }
    return super.render(context) + '\n';
  }
}

class Pre extends Node {}

class Code extends Node {
  render(Context context) {
    final text = super.render(context);
    if (text.contains('\n')) return '    ' + text.split('\n').join('\n    ');
    int len = 1;
    while (text.contains('`' * len)) len++; // Figure out the fencing length
    return '`' * len + text + '`' * len;
  }
}

class HorizontalRule extends Node {
  render(Context context) => '---\n';
}

class Emphasis extends Node {
  Emphasis(this.mark);

  final String mark;

  render(Context context) => '${mark}${super.render(context)}${mark}';
}

class Link extends Node {
  render(Context context) {
    final innerText = '[${super.render(context)}]';
    String href = attributes['href'];
    if (attributes.containsKey('title')) {
      href += ' "${attributes['title']}"';
    }

    if (context.inlineLinks) {
      return '${innerText}(${href})';
    }
    final id = '[id${_id++}]';
    context.footer.add('$id: ${href}');
    return '${innerText}${id}';
  }
}

class Image extends Node {
  render(Context context) {
    String src = attributes['src'];
    if (attributes.containsKey('title')) {
      src += ' "${attributes['title']}"';
    }
    final alt = attributes['alt'] ?? '';
    if (context.inlineImages) {
      return '![$alt](${src})';
    }
    final id = '[id${_id++}]';
    context.footer.add('${id}: ${src}');
    return '![${alt}]${id}';
  }
}

int _id = 1;