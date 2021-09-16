import 'package:flutter/material.dart';

class VideoViewLayout extends StatelessWidget {

  final List<Widget> children;

  final Orientation orientation;

  VideoViewLayout({this.children, this.orientation});

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    List<Widget> tmpWidgets = [];
    // Widget firstLevelWidget = Column;
    bool isColumnLayout = this.children.length > 2 && orientation == Orientation.portrait;

    for (int i = 0; i < this.children.length; i++) {
      tmpWidgets.add(this.children[i]);

      if (tmpWidgets.length == 2 || i == this.children.length - 1) {
        widgets.add(Expanded(
          child: !isColumnLayout ? Column(children: tmpWidgets) : Row(children: tmpWidgets)
        ));
        tmpWidgets = [];
      }
    }

    return !isColumnLayout ? Row(children: widgets) : Column(children: widgets);
  }

}
