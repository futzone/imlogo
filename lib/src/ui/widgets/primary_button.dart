import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_fonts.dart';
import 'package:dication/src/ui/widgets/hovered_widget.dart';
import 'package:flutter/material.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

class PrimaryButton extends StatelessWidget {
  final String? title;
  final void Function()? onTap;

  const PrimaryButton({super.key, this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoveredWidget(
      onPressed: onTap,
      builder: (focused) {
        return Container(
          padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 12),
          decoration: BoxDecoration(
            border: GradientBoxBorder(
              gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Colors.red]),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(80),
            color: focused ? Theme.of(context).primaryColor : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title ?? "Sinab ko'rish",
                style: TextStyle(
                  fontSize: context.isMobile ? 16 : 20,
                  fontFamily: mediumFamily,
                  color: focused ? Colors.white : Theme.of(context).primaryColor,
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
