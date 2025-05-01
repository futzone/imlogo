import 'dart:math';

import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_fonts.dart';
import 'package:dication/src/core/utils/get_rate_color.dart';
import 'package:dication/src/ui/screens/main_screens/before_start_screen.dart';
import 'package:dication/src/ui/widgets/hovered_widget.dart';
import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    final rate = Random().nextInt(6);
    return HoveredWidget(
      onPressed: () => BeforeStartScreen.show(context),
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
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Text(
                    "${rate == 0 ? rate + 1 : rate}",
                    style: TextStyle(
                      fontFamily: boldFamily,
                      fontSize: context.isMobile ? 24 : 32,
                      color: getRateColor(rate),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        "Diktant matni sarlavhasi va bu bir necha qator bo'lishi ham mumkin",
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
                                  "Davomiyligi: 9 min",
                                  style: TextStyle(fontFamily: mediumFamily),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.text_fields, size: 20),
                                Text(
                                  "So'zlar soni: 987 ta",
                                  style: TextStyle(fontFamily: mediumFamily),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.accessibility, size: 20),
                                Text(
                                  "Yosh chegarasi: 8-10 yosh (1-3-sinflar)",
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
                              "Davomiyligi: 9 min",
                              style: TextStyle(fontFamily: mediumFamily),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.text_fields, size: 20),
                            Text(
                              "So'zlar soni: 987 ta",
                              style: TextStyle(fontFamily: mediumFamily),
                            ),
                          ],
                        ),

                      if(!context.isMobile)
                        Row(
                          children: [
                            Icon(Icons.accessibility, size: 20),
                            Text(
                              "Yosh chegarasi: 8-10 yosh (1-3-sinflar)",
                              style: TextStyle(fontFamily: mediumFamily),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (!context.isMobile)
                  Text(
                    "Batafsil",
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
                      "Batafsil",
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
