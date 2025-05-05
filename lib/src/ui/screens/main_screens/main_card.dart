import 'dart:math';

import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_fonts.dart';
import 'package:dication/src/core/models/text_model.dart';
import 'package:dication/src/ui/screens/main_screens/before_start_screen.dart';
import 'package:dication/src/ui/widgets/hovered_widget.dart';
import 'package:flutter/material.dart';

class MainCard extends StatelessWidget {
  final TextModel text;

  const MainCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final issDone = Random().nextBool();
    return HoveredWidget(
      onPressed: () => BeforeStartScreen.show(context, text),
      builder: (focused) => AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(top: 16, left: 24, right: 24),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: focused ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Theme.of(context).cardColor,
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: Colors.transparent,
                    offset: Offset(1, 2),
                    spreadRadius: 2,
                    blurRadius: 3,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.4),
                    offset: Offset(1, 2),
                    spreadRadius: 2,
                    blurRadius: 3,
                  )
                ],
        ),
        child: Column(
          children: [
            Row(
              spacing: 16,
              children: [
                if (!issDone)
                  Icon(
                    Icons.circle_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                if (issDone)
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 32,
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        text.title,
                        style: TextStyle(
                          fontSize: context.isDesktop ? 18 : 14,
                          fontFamily: boldFamily,
                        ),
                      ),
                      if (context.isMobile)
                        Column(
                          spacing: 8,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.timelapse_outlined, size: 20),
                                Text(
                                  "Davomiyligi: ${text.time} min",
                                  style: TextStyle(fontFamily: mediumFamily),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.text_fields, size: 20),
                                Text(
                                  "So'zlar soni: ${text.length} ta",
                                  style: TextStyle(fontFamily: mediumFamily),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.accessibility, size: 20),
                                Text(
                                  "Yosh chegarasi: ${text.ageName} yosh, (${text.className})",
                                  style: TextStyle(fontFamily: mediumFamily),
                                ),
                              ],
                            ),
                          ],
                        ),
                      if (!context.isMobile)
                        Row(
                          spacing: 4,
                          children: [
                            Icon(Icons.timelapse_outlined, size: 20),
                            Text(
                              "Davomiyligi: ${text.time} min",
                              style: TextStyle(fontFamily: mediumFamily),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.text_fields, size: 20),
                            Text(
                              "So'zlar soni: ${text.length} ta",
                              style: TextStyle(fontFamily: mediumFamily),
                            ),
                          ],
                        ),
                      if (!context.isMobile)
                        Row(
                          children: [
                            Icon(Icons.accessibility, size: 20),
                            Text(
                              "Yosh chegarasi: ${text.ageName} yosh, (${text.className})",
                              style: TextStyle(fontFamily: mediumFamily),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (!context.isMobile)
                  Text(
                    "Boshlash",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                      fontFamily: mediumFamily,
                    ),
                  ),
                if (!context.isMobile)
                  Icon(
                    Icons.arrow_forward,
                    color: Theme.of(context).primaryColor,
                  )
              ],
            ),
            if (context.isMobile) SizedBox(height: 16),
            if (context.isMobile)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (context.isMobile)
                    Text(
                      "Boshlash",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                        fontFamily: mediumFamily,
                      ),
                    ),
                  if (context.isMobile)
                    Icon(
                      Icons.arrow_forward,
                      color: Theme.of(context).primaryColor,
                    )
                ],
              )
          ],
        ),
      ),
    );
  }
}
