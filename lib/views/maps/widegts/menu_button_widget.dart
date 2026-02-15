import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MenuButtonWidget extends StatelessWidget {
  const MenuButtonWidget({Key? key}) : super(key: key);

  void closeApp() {
    // Close the app
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 32,
          left: 16,
          child: Material(
            shape: const CircleBorder(),
            color: Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.black,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Menu'),
                      content: const Text('Options'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the dialog
                          },
                          child: const Text('Close'),
                        ),
                        TextButton(
                          onPressed: closeApp,
                          child: const Text('Close App'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
